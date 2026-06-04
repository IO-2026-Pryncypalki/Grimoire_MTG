import passport from 'passport';

jest.spyOn(passport, 'authenticate').mockImplementation(() => {
    return (req: any, _res: any, next: any) => {
        req.user = { id: 'user-1' };
        next();
    };
});

jest.mock('../src/backend/services/CardService', () => ({
    searchCards: jest.fn(),
    getCardDetails: jest.fn(),
}));

import request from 'supertest';
import express from 'express';
import cardRoute from '../src/backend/routes/cardRoute';
import { getCardDetails, searchCards } from '../src/backend/services/CardService';
import Card from '../src/backend/collection/Card';

const CARD_ID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

const app = express();
app.use(express.json());
app.use(passport.initialize());
app.use('/api/cards', cardRoute);

const makeCard = () => new Card({
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
    prices: { usd: 1.5, usd_foil: 2, eur: 1.2, eur_foil: 2.5 },
    image_uris: { normal: 'https://example.com/bolt.jpg' },
    scryfall_uri: 'https://scryfall.com/card/tsr/333',
});

describe('POST /api/cards/search', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('zwraca listę kart i total dla cardName', async () => {
        const card = makeCard();
        (searchCards as jest.Mock).mockResolvedValue({
            cards: [card],
            total: 1,
            noMatch: false,
            didYouMean: [],
            searchMode: 'direct',
        });

        const res = await request(app)
            .post('/api/cards/search')
            .send({ cardName: 'lightning' });

        expect(res.status).toBe(200);
        expect(searchCards).toHaveBeenCalledWith('lightning');
        expect(res.body.cards).toHaveLength(1);
        expect(res.body.cards[0].scryfallId).toBe(CARD_ID);
        expect(res.body.total).toBe(1);
    });

    test('400 gdy brak cardName', async () => {
        const res = await request(app).post('/api/cards/search').send({});

        expect(res.status).toBe(400);
        expect(searchCards).not.toHaveBeenCalled();
    });

    test('429 gdy Scryfall rate limit', async () => {
        (searchCards as jest.Mock).mockRejectedValue(new Error('Scryfall Rate Limit Exceeded'));

        const res = await request(app)
            .post('/api/cards/search')
            .send({ cardName: 'bolt' });

        expect(res.status).toBe(429);
    });

    test('zwraca noMatch i didYouMean gdy brak wyników', async () => {
        (searchCards as jest.Mock).mockResolvedValue({
            cards: [],
            total: 0,
            noMatch: true,
            didYouMean: ['Lightning Bolt'],
            searchMode: 'autocomplete',
        });

        const res = await request(app)
            .post('/api/cards/search')
            .send({ cardName: 'lighning' });

        expect(res.status).toBe(200);
        expect(res.body.noMatch).toBe(true);
        expect(res.body.didYouMean).toEqual(['Lightning Bolt']);
        expect(res.body.searchMode).toBe('autocomplete');
    });
});

describe('GET /api/cards/:scryfallId', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('zwraca szczegóły karty', async () => {
        (getCardDetails as jest.Mock).mockResolvedValue(makeCard());

        const res = await request(app).get(`/api/cards/${CARD_ID}`);

        expect(res.status).toBe(200);
        expect(getCardDetails).toHaveBeenCalledWith(CARD_ID);
        expect(res.body.name).toBe('Lightning Bolt');
        expect(res.body.oracleText).toBe('Lightning Bolt deals 3 damage to any target.');
        expect(res.body.manaCost).toBe('{R}');
    });

    test('400 gdy scryfallId nie jest UUID', async () => {
        const res = await request(app).get('/api/cards/not-a-uuid');

        expect(res.status).toBe(400);
        expect(getCardDetails).not.toHaveBeenCalled();
    });

    test('404 gdy karta nie istnieje', async () => {
        (getCardDetails as jest.Mock).mockRejectedValue(new Error('Card not found'));

        const res = await request(app).get(`/api/cards/${CARD_ID}`);

        expect(res.status).toBe(404);
    });
});
