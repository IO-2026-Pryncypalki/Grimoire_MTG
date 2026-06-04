import passport from 'passport';

jest.spyOn(passport, 'authenticate').mockImplementation(() => {
    return (req: any, _res: any, next: any) => {
        req.user = { id: 'user-1' };
        next();
    };
});

jest.mock('../src/backend/services/CardService', () => ({
    ensureCardInDb: jest.fn(),
}));

jest.mock('../src/backend/collection/Collection', () => ({
    __esModule: true,
    default: {
        load: jest.fn(),
    },
}));

import request from 'supertest';
import express from 'express';
import collectionRoute from '../src/backend/routes/collectionRoute';
import { ensureCardInDb } from '../src/backend/services/CardService';
import Collection from '../src/backend/collection/Collection';

const CARD_ID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

const app = express();
app.use(express.json());
app.use(passport.initialize());
app.use('/api/collection', collectionRoute);

describe('POST /api/collection', () => {
    const mockAddCardAndSave = jest.fn();

    beforeEach(() => {
        jest.clearAllMocks();
        (Collection.load as jest.Mock).mockResolvedValue({
            addCardAndSave: mockAddCardAndSave,
        });
        (ensureCardInDb as jest.Mock).mockResolvedValue({
            get: () => ({ scryfallId: CARD_ID, name: 'Lightning Bolt' }),
        });
        mockAddCardAndSave.mockResolvedValue({
            scryfallId: CARD_ID,
            quantity: 2,
            condition: 'NM',
            isFoil: false,
        });
    });

    test('dodaje kartę ze skanu po ensureCardInDb', async () => {
        const res = await request(app)
            .post('/api/collection')
            .send({ scryfallId: CARD_ID, quantity: 2, condition: 'NM' });

        expect(res.status).toBe(201);
        expect(ensureCardInDb).toHaveBeenCalledWith(CARD_ID);
        expect(mockAddCardAndSave).toHaveBeenCalledWith(
            expect.anything(),
            { quantity: 2, condition: 'NM', isFoil: false },
        );
        expect(res.body).toEqual({
            message: 'Card added to collection',
            entry: {
                scryfallId: CARD_ID,
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            },
        });
    });

    test('400 gdy scryfallId nie jest UUID', async () => {
        const res = await request(app)
            .post('/api/collection')
            .send({ scryfallId: 'not-a-uuid' });

        expect(res.status).toBe(400);
        expect(res.body.message).toMatch(/UUID/);
        expect(ensureCardInDb).not.toHaveBeenCalled();
    });

    test('400 gdy condition jest nieprawidłowy', async () => {
        const res = await request(app)
            .post('/api/collection')
            .send({ scryfallId: CARD_ID, condition: 'FAKE' });

        expect(res.status).toBe(400);
        expect(res.body.message).toBe('condition is invalid');
    });

    test('404 gdy Scryfall nie zna karty', async () => {
        (ensureCardInDb as jest.Mock).mockRejectedValue(new Error('Card not found'));

        const res = await request(app)
            .post('/api/collection')
            .send({ scryfallId: CARD_ID });

        expect(res.status).toBe(404);
        expect(res.body.message).toBe('Card not found');
    });

    test('429 gdy Scryfall rate limit', async () => {
        (ensureCardInDb as jest.Mock).mockRejectedValue(new Error('Scryfall Rate Limit Exceeded'));

        const res = await request(app)
            .post('/api/collection')
            .send({ scryfallId: CARD_ID });

        expect(res.status).toBe(429);
    });
});

describe('DELETE /api/collection/:scryfallId', () => {
    const mockRemoveCard = jest.fn();

    beforeEach(() => {
        jest.clearAllMocks();
        (Collection.load as jest.Mock).mockResolvedValue({
            removeCard: mockRemoveCard,
        });
    });

    test('200 gdy wpis usunięty', async () => {
        mockRemoveCard.mockResolvedValue(1);

        const res = await request(app)
            .delete(`/api/collection/${CARD_ID}`)
            .query({ condition: 'NM', isFoil: 'false' });

        expect(res.status).toBe(200);
        expect(mockRemoveCard).toHaveBeenCalledWith(CARD_ID, 'NM', false);
    });

    test('404 gdy brak wpisu', async () => {
        mockRemoveCard.mockResolvedValue(0);

        const res = await request(app)
            .delete(`/api/collection/${CARD_ID}`)
            .query({ condition: 'NM', isFoil: 'false' });

        expect(res.status).toBe(404);
        expect(res.body.message).toBe('Entry not found');
    });
});
