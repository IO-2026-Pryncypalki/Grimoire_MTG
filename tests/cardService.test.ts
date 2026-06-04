jest.mock('../src/backend/models/Card', () => ({
    Card: {
        findByPk: jest.fn(),
        findAll: jest.fn(),
        create: jest.fn(),
        upsert: jest.fn(),
    },
}));

jest.mock('../src/backend/repositories/CardLegalityRepository', () => ({
    hasLegalities: jest.fn(),
    upsertCardLegalities: jest.fn(),
}));

import { Card as CardModel } from '../src/backend/models/Card';
import { hasLegalities, upsertCardLegalities } from '../src/backend/repositories/CardLegalityRepository';
import { ensureCardInDb, getCardDetails, searchCards } from '../src/backend/services/CardService';

const CARD_ID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

const scryfallPayload = {
    id: CARD_ID,
    name: 'Lightning Bolt',
    set: 'tsr',
    set_name: 'Time Spiral Remastered',
    collector_number: '333',
    lang: 'en',
    mana_cost: '{R}',
    cmc: 1,
    type_line: 'Instant',
    oracle_text: 'Lightning Bolt deals 3 damage to any target.',
    power: null,
    toughness: null,
    rarity: 'common',
    colors: ['R'],
    color_identity: ['R'],
    prices: { usd: '1.50', usd_foil: '2.00', eur: '1.20', eur_foil: '2.50' },
    image_uris: { normal: 'https://example.com/bolt.jpg' },
    scryfall_uri: 'https://scryfall.com/card/tsr/333',
    legalities: {
        standard: 'not_legal',
        modern: 'legal',
        legacy: 'legal',
        vintage: 'legal',
        commander: 'legal',
        pioneer: 'not_legal',
        pauper: 'legal',
    },
};

const dbCardModel = () => ({
    get: () => ({
        scryfallId: CARD_ID,
        name: 'Lightning Bolt',
        setCode: 'tsr',
        setName: 'Time Spiral Remastered',
        collectorNumber: '333',
        lang: 'en',
        manaCost: '{R}',
        cmc: 1,
        typeLine: 'Instant',
        oracleText: 'Lightning Bolt deals 3 damage to any target.',
        power: null,
        toughness: null,
        rarity: 'common',
        colors: ['R'],
        colorIdentity: ['R'],
        imageUri: 'https://example.com/bolt.jpg',
        priceUsd: 1.5,
        priceUsdFoil: 2,
        priceEur: 1.2,
        priceEurFoil: 2.5,
        scryfallUri: 'https://scryfall.com/card/tsr/333',
    }),
});

describe('ensureCardInDb', () => {
    let fetchMock: jest.Mock;

    beforeEach(() => {
        jest.clearAllMocks();
        fetchMock = jest.fn();
        global.fetch = fetchMock;
        (CardModel.findAll as jest.Mock).mockResolvedValue([]);
        (hasLegalities as jest.Mock).mockResolvedValue(true);
        (upsertCardLegalities as jest.Mock).mockResolvedValue(undefined);
    });

    test('zwraca kartę z bazy bez wołania Scryfall gdy legalności są zapisane', async () => {
        const existing = { scryfallId: CARD_ID };
        (CardModel.findByPk as jest.Mock).mockResolvedValue(existing);

        const result = await ensureCardInDb(CARD_ID);

        expect(result).toBe(existing);
        expect(fetchMock).not.toHaveBeenCalled();
        expect(CardModel.create).not.toHaveBeenCalled();
        expect(hasLegalities).toHaveBeenCalledWith(CARD_ID);
    });

    test('uzupełnia legalności ze Scryfall gdy karta jest w bazie bez legalności', async () => {
        const existing = { scryfallId: CARD_ID };
        (CardModel.findByPk as jest.Mock).mockResolvedValue(existing);
        (hasLegalities as jest.Mock).mockResolvedValue(false);
        fetchMock.mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => scryfallPayload,
        });

        const result = await ensureCardInDb(CARD_ID);

        expect(result).toBe(existing);
        expect(fetchMock).toHaveBeenCalledWith(
            `https://api.scryfall.com/cards/${CARD_ID}`,
        );
        expect(upsertCardLegalities).toHaveBeenCalledWith(
            expect.arrayContaining([
                expect.objectContaining({ scryfallId: CARD_ID, format: 'Modern', status: 'legal' }),
                expect.objectContaining({ scryfallId: CARD_ID, format: 'Standard', status: 'not_legal' }),
            ]),
        );
    });

    test('pobiera ze Scryfall i tworzy rekord gdy brak w bazie', async () => {
        (CardModel.findByPk as jest.Mock).mockResolvedValue(null);
        (hasLegalities as jest.Mock).mockResolvedValue(false);
        const created = { scryfallId: CARD_ID };
        (CardModel.create as jest.Mock).mockResolvedValue(created);
        fetchMock.mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => scryfallPayload,
        });

        const result = await ensureCardInDb(CARD_ID);

        expect(fetchMock).toHaveBeenCalledWith(
            `https://api.scryfall.com/cards/${CARD_ID}`,
        );
        expect(CardModel.create).toHaveBeenCalledWith(
            expect.objectContaining({
                scryfallId: CARD_ID,
                name: 'Lightning Bolt',
                setCode: 'tsr',
            }),
        );
        expect(upsertCardLegalities).toHaveBeenCalledWith(
            expect.arrayContaining([
                expect.objectContaining({ format: 'Modern', status: 'legal' }),
            ]),
        );
        expect(result).toBe(created);
    });

    test('rzuca Card not found gdy Scryfall zwraca 404', async () => {
        (CardModel.findByPk as jest.Mock).mockResolvedValue(null);
        fetchMock.mockResolvedValue({ ok: false, status: 404 });

        await expect(ensureCardInDb(CARD_ID)).rejects.toThrow('Card not found');
    });

    test('rzuca Scryfall Rate Limit Exceeded gdy Scryfall zwraca 429', async () => {
        (CardModel.findByPk as jest.Mock).mockResolvedValue(null);
        fetchMock.mockResolvedValue({ ok: false, status: 429 });

        await expect(ensureCardInDb(CARD_ID)).rejects.toThrow(
            'Scryfall Rate Limit Exceeded',
        );
    });
});

describe('searchCards', () => {
    let fetchMock: jest.Mock;

    beforeEach(() => {
        jest.clearAllMocks();
        fetchMock = jest.fn();
        global.fetch = fetchMock;
        (CardModel.findAll as jest.Mock).mockResolvedValue([]);
    });

    test('zwraca listę z Scryfall bez CardModel.create', async () => {
        fetchMock.mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => ({
                total_cards: 2,
                data: [scryfallPayload, { ...scryfallPayload, id: 'b2c3d4e5-f6a7-8901-bcde-f12345678901', set: 'lea' }],
            }),
        });

        const result = await searchCards('lightning');

        expect(result.cards).toHaveLength(2);
        expect(result.total).toBe(2);
        expect(result.cards[0].getName()).toBe('Lightning Bolt');
        expect(CardModel.create).not.toHaveBeenCalled();
        expect(fetchMock.mock.calls[0][0]).toContain('/cards/search?q=lightning');
    });

    test('404 od Scryfall zwraca pustą listę lub tylko lokalne wyniki', async () => {
        fetchMock.mockResolvedValue({ ok: false, status: 404 });
        (CardModel.findAll as jest.Mock).mockResolvedValue([]);

        const result = await searchCards('unknownxyz');

        expect(result).toEqual({ cards: [], total: 0 });
        expect(CardModel.create).not.toHaveBeenCalled();
    });

    test('łączy wyniki Scryfall z lokalną bazą bez duplikatów', async () => {
        const localId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
        (CardModel.findAll as jest.Mock).mockResolvedValue([dbCardModel()]);
        fetchMock.mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => ({
                total_cards: 1,
                data: [scryfallPayload],
            }),
        });

        const result = await searchCards('lightning');

        expect(result.cards).toHaveLength(1);
        expect(result.cards[0].getScryfallId()).toBe(CARD_ID);
        expect(CardModel.create).not.toHaveBeenCalled();
    });

    test('rzuca błąd dla pustego cardName', async () => {
        await expect(searchCards('   ')).rejects.toThrow('cardName is required');
    });
});

describe('getCardDetails', () => {
    let fetchMock: jest.Mock;

    beforeEach(() => {
        jest.clearAllMocks();
        fetchMock = jest.fn();
        global.fetch = fetchMock;
        (upsertCardLegalities as jest.Mock).mockResolvedValue(undefined);
        (CardModel.upsert as jest.Mock).mockResolvedValue(undefined);
        fetchMock.mockResolvedValue({
            ok: true,
            status: 200,
            json: async () => scryfallPayload,
        });
    });

    test('odświeża kartę ze Scryfall i zapisuje do bazy', async () => {
        (CardModel.findByPk as jest.Mock).mockResolvedValue(dbCardModel());

        const card = await getCardDetails(CARD_ID);

        expect(card.getName()).toBe('Lightning Bolt');
        expect(card.getOracleText()).toBe('Lightning Bolt deals 3 damage to any target.');
        expect(fetchMock).toHaveBeenCalledWith(
            `https://api.scryfall.com/cards/${CARD_ID}`,
        );
        expect(CardModel.upsert).toHaveBeenCalledWith(
            expect.objectContaining({
                scryfallId: CARD_ID,
                name: 'Lightning Bolt',
                imageUri: 'https://example.com/bolt.jpg',
            }),
        );
        expect(upsertCardLegalities).toHaveBeenCalled();
    });

    test('zwraca domenę ze Scryfall gdy upsert nie ma wiersza w bazie', async () => {
        (CardModel.findByPk as jest.Mock).mockResolvedValue(null);

        const card = await getCardDetails(CARD_ID);

        expect(card.getScryfallId()).toBe(CARD_ID);
        expect(card.getTypeLine()).toBe('Instant');
        expect(CardModel.upsert).toHaveBeenCalled();
    });
});
