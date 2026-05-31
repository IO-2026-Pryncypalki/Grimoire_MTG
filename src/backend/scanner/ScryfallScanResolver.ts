import Card from '../collection/Card';
import { CardScanResult } from './parseCardScan';
import { mapScryfallJsonToCard } from './scryfallCardMapper';

export interface ScryfallScanResult {
  cards: Card[];
  total: number;
}

const BASE = 'https://api.scryfall.com';
const UA = 'GrimoireMTG/1.0 contact:github.com/grimoire-mtg';
const BASE_DELAY_MS = 200;

export default class ScryfallScanResolver {
  private lastRequestTime = 0;

  constructor(private readonly delayMs = BASE_DELAY_MS) {}

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
    const res = await fetch(url, {
      headers: { 'User-Agent': UA, Accept: 'application/json' },
    });

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

    if (set && collectorNumber) {
      const num = this.collectorBase(collectorNumber);
      const url = `${BASE}/cards/${set.toLowerCase()}/${num}`;
      const { ok, status, data } = await this.scryfallFetch(url);
      if (ok) {
        return {
          cards: [mapScryfallJsonToCard(data!)],
          total: 1,
        };
      }
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (name && set) {
      const exact = await this.scryfallSearch(`!"${name}" e:${set.toLowerCase()}`);
      if (exact.total > 0) return exact;

      const url = `${BASE}/cards/named?fuzzy=${encodeURIComponent(name)}&set=${set.toLowerCase()}`;
      const { ok, status, data } = await this.scryfallFetch(url);
      if (ok) {
        return {
          cards: [mapScryfallJsonToCard(data!)],
          total: 1,
        };
      }
      if (status === 429) throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (name) {
      const exact = await this.scryfallSearch(`!"${name}"`);
      if (exact.total > 0) return exact;

      const url = `${BASE}/cards/named?fuzzy=${encodeURIComponent(name)}`;
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
}
