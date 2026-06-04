import { Op } from 'sequelize';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';
import { extractLegalitiesRows } from '../deck/scryfallFormatMap';
import { hasLegalities, upsertCardLegalities } from '../repositories/CardLegalityRepository';
import { mapScryfallJsonToCard, scryfallJsonToCardModelFields } from '../scanner/scryfallCardMapper';

const SCRYFALL_BASE = 'https://api.scryfall.com';
const RATE_LIMIT_MS = 100;
let lastRequestTime = 0;

export interface SearchCardsResult {
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

async function fetchScryfallJson(url: string): Promise<Record<string, unknown>> {
    await waitForRateLimit();
    const response = await fetch(url);

    if (response.status === 429) {
        throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (!response.ok) {
        throw new Error('Card not found');
    }

    return (await response.json()) as Record<string, unknown>;
}

function assertNonEmptyCardName(cardName: string): string {
    const trimmed = cardName?.trim();
    if (!trimmed) {
        throw new Error('cardName is required');
    }
    return trimmed;
}

function mergeSearchResults(scryfallCards: Card[], localCards: Card[]): Card[] {
    const seen = new Set(scryfallCards.map(c => c.getScryfallId()));
    const merged = [...scryfallCards];
    for (const local of localCards) {
        const id = local.getScryfallId();
        if (!seen.has(id)) {
            seen.add(id);
            merged.push(local);
        }
    }
    return merged;
}

export async function searchCards(cardName: string): Promise<SearchCardsResult> {
    const query = assertNonEmptyCardName(cardName);

    const localRows = await CardModel.findAll({
        where: { name: { [Op.iLike]: `%${query}%` } },
        limit: 50,
    });
    const localCards = localRows.map(row =>
        Card.fromModel(row as InstanceType<typeof CardModel>),
    );

    const searchUrl =
        `${SCRYFALL_BASE}/cards/search?q=${encodeURIComponent(query)}&unique=prints&order=name`;

    await waitForRateLimit();
    const response = await fetch(searchUrl);

    if (response.status === 429) {
        throw new Error('Scryfall Rate Limit Exceeded');
    }

    if (response.status === 404) {
        return {
            cards: localCards,
            total: localCards.length,
        };
    }

    if (!response.ok) {
        throw new Error('Scryfall search failed');
    }

    const data = (await response.json()) as Record<string, unknown>;
    const total = (data.total_cards as number) ?? 0;
    const items = (data.data as Record<string, unknown>[]) ?? [];
    const scryfallCards = items.map(mapScryfallJsonToCard);

    return {
        cards: mergeSearchResults(scryfallCards, localCards),
        total: Math.max(total, scryfallCards.length),
    };
}

export async function getCardDetails(scryfallId: string): Promise<Card> {
    const data = await fetchScryfallJson(
        `${SCRYFALL_BASE}/cards/${encodeURIComponent(scryfallId)}`,
    );
    const fields = scryfallJsonToCardModelFields(data);
    await CardModel.upsert(fields);
    await syncCardLegalitiesFromScryfall(scryfallId, data);

    const row = await CardModel.findByPk(scryfallId);
    if (!row) {
        return mapScryfallJsonToCard(data);
    }
    return Card.fromModel(row as InstanceType<typeof CardModel>);
}

export async function syncCardLegalitiesFromScryfall(
    scryfallId: string,
    data: Record<string, unknown>,
): Promise<void> {
    const legalities = data.legalities as Record<string, string> | undefined;
    await upsertCardLegalities(extractLegalitiesRows(scryfallId, legalities));
}

export async function ensureLegalitiesInDb(scryfallId: string): Promise<void> {
    if (await hasLegalities(scryfallId)) {
        return;
    }

    const data = await fetchScryfallJson(
        `${SCRYFALL_BASE}/cards/${encodeURIComponent(scryfallId)}`,
    );
    await syncCardLegalitiesFromScryfall(scryfallId, data);
}

export async function ensureCardInDb(
    scryfallId: string,
): Promise<InstanceType<typeof CardModel>> {
    const existing = await CardModel.findByPk(scryfallId);
    if (existing) {
        await ensureLegalitiesInDb(scryfallId);
        return existing;
    }

    const data = await fetchScryfallJson(
        `${SCRYFALL_BASE}/cards/${encodeURIComponent(scryfallId)}`,
    );
    const created = await CardModel.create(scryfallJsonToCardModelFields(data));
    await syncCardLegalitiesFromScryfall(scryfallId, data);
    return created;
}
