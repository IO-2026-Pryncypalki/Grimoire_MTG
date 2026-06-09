import Card from '../collection/Card';
import { mapScryfallJsonToCard } from './scryfallCardMapper';
import { scryfallFetch, SCRYFALL_BASE } from './scryfallHttp';
const RATE_LIMIT_MS = 100;
let lastRequestTime = 0;

export type ScryfallSearchMode = 'direct' | 'autocomplete' | 'local_fuzzy';

export interface ScryfallCardSearchResult {
    cards: Card[];
    total: number;
}

async function waitForRateLimit(): Promise<void> {
    const now = Date.now();
    let delay = 0;

    if (now - lastRequestTime < RATE_LIMIT_MS) {
        delay = RATE_LIMIT_MS - (now - lastRequestTime);
    }

    lastRequestTime = now + delay;

    if (delay > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
    }
}

function escapeScryfallQuotedName(name: string): string {
    return name.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
}

/** True when the user likely types a plain card name (not Scryfall syntax). */
export function hasScryfallSearchSyntax(query: string): boolean {
    // Detect colon-based filters (c:R, t:creature), quoted strings, and
    // equals-based filters (c=WU, cmc=3) used by structured search UI.
    return /[:!"'=]/.test(query);
}

export function buildScryfallSearchQuery(query: string): string {
    if (hasScryfallSearchSyntax(query)) {
        return query;
    }
    return `name:${query}`;
}

export function buildOrQueryFromNames(names: string[]): string {
    return names
        .slice(0, 5)
        .map((name) => `!"${escapeScryfallQuotedName(name)}"`)
        .join(' or ');
}

export async function fetchAutocompleteNames(query: string): Promise<string[]> {
    if (query.trim().length < 2) {
        return [];
    }

    const url = `${SCRYFALL_BASE}/cards/autocomplete?q=${encodeURIComponent(query)}`;
    await waitForRateLimit();
    const response = await scryfallFetch(url);

    if (response.status === 429) {
        throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (!response.ok) {
        return [];
    }

    const data = (await response.json()) as { data?: string[] };
    return Array.isArray(data.data) ? data.data : [];
}

export async function searchScryfallCards(
    q: string,
): Promise<ScryfallCardSearchResult | null> {
    const searchUrl =
        `${SCRYFALL_BASE}/cards/search?q=${encodeURIComponent(q)}&unique=prints&order=name`;

    await waitForRateLimit();
    const response = await scryfallFetch(searchUrl);

    if (response.status === 429) {
        throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (response.status === 404) {
        return null;
    }

    if (!response.ok) {
        throw new Error('Scryfall search failed');
    }

    const data = (await response.json()) as Record<string, unknown>;
    const total = (data.total_cards as number) ?? 0;
    const items = (data.data as Record<string, unknown>[]) ?? [];
    const cards = items.map(mapScryfallJsonToCard);

    return {
        cards,
        total: Math.max(total, cards.length),
    };
}
