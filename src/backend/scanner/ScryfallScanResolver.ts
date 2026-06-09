import Card from '../collection/Card';
import { CardScanResult } from './parseCardScan';
import { mapScryfallJsonToCard } from './scryfallCardMapper';
import { scryfallFetch, SCRYFALL_BASE } from './scryfallHttp';
import { CardSymSpell } from './symspell';

export interface ScryfallScanResult {
  cards: Card[];
  total: number;
}

export type ResolveByNameResult =
  | { kind: 'unique'; card: Card }
  | { kind: 'ambiguous'; cards: Card[] }
  | { kind: 'not_found' }
  | { kind: 'rate_limit' };

const BASE = SCRYFALL_BASE;
export const BASE_DELAY_MS = 200;

// Fallback chain (effectiveName = symspell(name) ?? name, computed upfront):
//   1. set + collector  →  GET /cards/{set}/{num}  (accepted only if name matches effectiveName)
//   2. effectiveName + set →  search !"effectiveName" e:set
//      fuzzy + set         →  /cards/named?fuzzy&set
//   3. effectiveName only  →  search !"effectiveName"
//      fuzzy               →  /cards/named?fuzzy

export default class ScryfallScanResolver {
  private lastRequestTime = 0;

  constructor(
    private readonly delayMs = BASE_DELAY_MS,
    private readonly symspell?: CardSymSpell,
  ) {}

  private async waitForRateLimit(): Promise<void> {
    const now = Date.now();
    const elapsed = now - this.lastRequestTime;
    if (elapsed < this.delayMs) {
      await new Promise((r) => setTimeout(r, this.delayMs - elapsed));
    }
    this.lastRequestTime = Date.now();
  }

  private async scryfallFetch(
    url: string,
    retries = 4,
  ): Promise<{ ok: boolean; status: number; data?: Record<string, unknown> }> {
    await this.waitForRateLimit();
    const res = await scryfallFetch(url);

    if (res.status === 429) {
      if (retries === 0) return { ok: false, status: 429 };
      const retryAfter = parseInt(res.headers.get('Retry-After') ?? '5', 10) * 1000;
      await new Promise((r) => setTimeout(r, retryAfter));
      return this.scryfallFetch(url, retries - 1);
    }

    if (!res.ok) return { ok: false, status: res.status };
    return { ok: true, status: res.status, data: (await res.json()) as Record<string, unknown> };
  }

  private collectorBase(c: string): string {
    return c.split('/')[0].replace(/^0+/, '') || '0';
  }

  private async scryfallSearch(q: string): Promise<ScryfallScanResult> {
    const url = `${BASE}/cards/search?q=${encodeURIComponent(q)}&unique=prints`;
    const { ok, status, data } = await this.scryfallFetch(url);
    if (!ok) {
      if (status === 404) return { cards: [], total: 0 };
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
      return { cards: [], total: 0 };
    }

    const total = (data!.total_cards as number) ?? 0;
    const items = (data!.data as Record<string, unknown>[]) ?? [];
    return {
      cards: items.map(mapScryfallJsonToCard),
      total,
    };
  }

  public async resolve(parsed: CardScanResult): Promise<ScryfallScanResult> {
    const { name, set, collectorNumber } = parsed;

    // Apply symspell upfront; symspell terms are lowercased, which Scryfall accepts.
    const effectiveName = (name && this.symspell)
      ? (this.symspell.lookup(name)[0]?.term ?? name)
      : name;

    if (set && collectorNumber) {
      const num = this.collectorBase(collectorNumber);
      const url = `${BASE}/cards/${set.toLowerCase()}/${num}`;
      const { ok, status, data } = await this.scryfallFetch(url);
      if (ok) {
        const card = mapScryfallJsonToCard(data!);
        const nameOk = !effectiveName ||
          (card.getName() ?? '').toLowerCase() === effectiveName.toLowerCase();
        if (nameOk) return { cards: [card], total: 1 };
        // name mismatch — fall through to name-based steps
      }
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (effectiveName && set) {
      const exact = await this.scryfallSearch(`!"${effectiveName}" e:${set.toLowerCase()}`);
      if (exact.total > 0) return exact;

      const url = `${BASE}/cards/named?fuzzy=${encodeURIComponent(effectiveName)}&set=${set.toLowerCase()}`;
      const { ok, status, data } = await this.scryfallFetch(url);
      if (ok) {
        return {
          cards: [mapScryfallJsonToCard(data!)],
          total: 1,
        };
      }
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (effectiveName) {
      const exact = await this.scryfallSearch(`!"${effectiveName}"`);
      if (exact.total > 0) return exact;

      const url = `${BASE}/cards/named?fuzzy=${encodeURIComponent(effectiveName)}`;
      const { ok, status, data } = await this.scryfallFetch(url);
      if (ok) {
        return {
          cards: [mapScryfallJsonToCard(data!)],
          total: 1,
        };
      }
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
    }

    return { cards: [], total: 0 };
  }

  private async fetchNamedCard(
    name: string,
    fuzzy: boolean,
  ): Promise<{ card: Card } | 'not_found' | 'rate_limit'> {
    const param = fuzzy ? 'fuzzy' : 'exact';
    const url = `${BASE}/cards/named?${param}=${encodeURIComponent(name)}`;
    const { ok, status, data } = await this.scryfallFetch(url);
    if (ok) {
      return { card: mapScryfallJsonToCard(data!) };
    }
    if (status === 429) {
      return 'rate_limit';
    }
    return 'not_found';
  }

  public async resolveByName(name: string): Promise<ResolveByNameResult> {
    const trimmed = name.trim();
    if (trimmed.length === 0) {
      return { kind: 'not_found' };
    }

    const effectiveName = this.symspell
      ? (this.symspell.lookup(trimmed)[0]?.term ?? trimmed)
      : trimmed;

    const exactNamed = await this.fetchNamedCard(effectiveName, false);
    if (exactNamed === 'rate_limit') {
      return { kind: 'rate_limit' };
    }
    if (exactNamed !== 'not_found') {
      return { kind: 'unique', card: exactNamed.card };
    }

    const exactSearch = await this.scryfallSearch(`!"${effectiveName}"`);
    if (exactSearch.total === 1) {
      return { kind: 'unique', card: exactSearch.cards[0] };
    }

    const fuzzyNamed = await this.fetchNamedCard(effectiveName, true);
    if (fuzzyNamed === 'rate_limit') {
      return { kind: 'rate_limit' };
    }
    if (fuzzyNamed !== 'not_found') {
      return { kind: 'unique', card: fuzzyNamed.card };
    }

    return { kind: 'not_found' };
  }
}
