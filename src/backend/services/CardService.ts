import { Op, Sequelize } from 'sequelize';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';
import { extractLegalitiesRows } from '../deck/scryfallFormatMap';
import { hasLegalities, upsertCardLegalities } from '../repositories/CardLegalityRepository';
import { mapScryfallJsonToCard, scryfallJsonToCardModelFields } from '../scanner/scryfallCardMapper';
import { scryfallFetch, SCRYFALL_BASE } from '../scanner/scryfallHttp';
import {
    buildOrQueryFromNames,
    buildScryfallSearchQuery,
    fetchAutocompleteNames,
    ScryfallSearchMode,
    searchScryfallCards,
} from '../scanner/scryfallSearch';
const RATE_LIMIT_MS = 100;
const LOCAL_TRGM_THRESHOLD = 0.25;
const LOCAL_TRGM_LIMIT = 20;
let lastRequestTime = 0;

export interface SearchCardsResult {
    cards: Card[];
    total: number;
    noMatch: boolean;
    didYouMean: string[];
    searchMode: ScryfallSearchMode;
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
    const response = await scryfallFetch(url);

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

async function findLocalCardsByIlike(query: string): Promise<Card[]> {
    const localRows = await CardModel.findAll({
        where: { name: { [Op.iLike]: `%${query}%` } },
        limit: 50,
    });
    return localRows.map(row =>
        Card.fromModel(row as InstanceType<typeof CardModel>),
    );
}

async function findLocalCardsByTrgm(
    query: string,
): Promise<{ cards: Card[]; names: string[] }> {
    const localRows = await CardModel.findAll({
        where: Sequelize.where(
            Sequelize.fn('similarity', Sequelize.col('name'), query),
            Op.gt,
            LOCAL_TRGM_THRESHOLD,
        ),
        order: [[Sequelize.fn('similarity', Sequelize.col('name'), query), 'DESC']],
        limit: LOCAL_TRGM_LIMIT,
    });
    const cards = localRows.map(row =>
        Card.fromModel(row as InstanceType<typeof CardModel>),
    );
    const names = cards
        .map((c) => c.getName())
        .filter((n): n is string => n != null);
    return { cards, names };
}

export async function searchCards(cardName: string): Promise<SearchCardsResult> {
    const query = assertNonEmptyCardName(cardName);

    const localIlikeCards = await findLocalCardsByIlike(query);
    let searchMode: ScryfallSearchMode = 'direct';
    let didYouMean: string[] = [];

    const primaryResult = await searchScryfallCards(buildScryfallSearchQuery(query));
    let scryfallCards = primaryResult?.cards ?? [];
    let total = primaryResult?.total ?? 0;

    if (scryfallCards.length === 0) {
        const suggestions = await fetchAutocompleteNames(query);
        if (suggestions.length > 0) {
            didYouMean = suggestions.slice(0, 5);
            const orQuery = buildOrQueryFromNames(suggestions);
            const fallbackResult = await searchScryfallCards(orQuery);
            if (fallbackResult && fallbackResult.cards.length > 0) {
                scryfallCards = fallbackResult.cards;
                total = fallbackResult.total;
                searchMode = 'autocomplete';
            }
        }
    }

    let localCards = localIlikeCards;
    if (localIlikeCards.length === 0) {
        const trgm = await findLocalCardsByTrgm(query);
        if (trgm.cards.length > 0) {
            localCards = trgm.cards;
            if (searchMode === 'direct' && scryfallCards.length === 0) {
                searchMode = 'local_fuzzy';
                didYouMean = trgm.names.slice(0, 5);
            }
        }
    }

    const cards = mergeSearchResults(scryfallCards, localCards);
    const mergedTotal = Math.max(total, cards.length, localCards.length);

    return {
        cards,
        total: mergedTotal,
        noMatch: cards.length === 0,
        didYouMean,
        searchMode,
    };
}

export async function getCardDetails(scryfallId: string): Promise<Card> {
    const existing = await CardModel.findByPk(scryfallId);
    if (existing) {
        await ensureLegalitiesInDb(scryfallId);
        return Card.fromModel(existing as InstanceType<typeof CardModel>);
    }
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
