jest.mock('../src/backend/repositories/DeckRepository', () => ({
    getByIdForUser: jest.fn(),
    clearDeckCardsForUser: jest.fn(),
    addCardToDeckForUser: jest.fn(),
}));

jest.mock('../src/backend/services/CardService', () => ({
    ensureCardInDb: jest.fn(),
}));

import Card from '../src/backend/collection/Card';
import ScryfallScanResolver from '../src/backend/scanner/ScryfallScanResolver';
import { importDeckFromList } from '../src/backend/services/DeckListImportService';
import { ensureCardInDb } from '../src/backend/services/CardService';
import {
    addCardToDeckForUser,
    clearDeckCardsForUser,
    getByIdForUser,
} from '../src/backend/repositories/DeckRepository';

const USER_ID = 'user-1';
const DECK_ID = 'deck-1';
const SCRYFALL_SOL_RING = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const SCRYFALL_PLAINS = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

const makeCard = (scryfallId: string, name: string): Card =>
    new Card({ id: scryfallId, name, set: 'm21', type_line: 'Artifact' });

describe('importDeckFromList', () => {
    let resolver: ScryfallScanResolver;

    beforeEach(() => {
        jest.clearAllMocks();
        resolver = new ScryfallScanResolver(0);
        (getByIdForUser as jest.Mock).mockResolvedValue({
            id: DECK_ID,
            userId: USER_ID,
            name: 'Test Deck',
            format: 'Commander',
        });
        (ensureCardInDb as jest.Mock).mockResolvedValue({
            get: (field: string) => (field === 'name' ? 'Sol Ring' : SCRYFALL_SOL_RING),
        });
        (addCardToDeckForUser as jest.Mock).mockResolvedValue({});
        (clearDeckCardsForUser as jest.Mock).mockResolvedValue(true);
    });

    test('imports cards in merge mode without clearing deck', async () => {
        jest.spyOn(resolver, 'resolveByName')
            .mockResolvedValueOnce({ kind: 'unique', card: makeCard(SCRYFALL_SOL_RING, 'Sol Ring') })
            .mockResolvedValueOnce({ kind: 'unique', card: makeCard(SCRYFALL_PLAINS, 'Plains') });

        const result = await importDeckFromList(
            USER_ID,
            DECK_ID,
            {
                text: '1 Sol Ring\n2 Plains',
                mode: 'merge',
            },
            resolver,
        );

        expect(clearDeckCardsForUser).not.toHaveBeenCalled();
        expect(addCardToDeckForUser).toHaveBeenCalledTimes(2);
        expect(result.imported).toHaveLength(2);
        expect(result.failed).toHaveLength(0);
        expect(result.clearedExisting).toBe(false);
    });

    test('clears deck before import in replace mode', async () => {
        jest.spyOn(resolver, 'resolveByName').mockResolvedValue({
            kind: 'unique',
            card: makeCard(SCRYFALL_SOL_RING, 'Sol Ring'),
        });

        const result = await importDeckFromList(
            USER_ID,
            DECK_ID,
            {
                text: '1 Sol Ring',
                mode: 'replace',
            },
            resolver,
        );

        expect(clearDeckCardsForUser).toHaveBeenCalledWith(DECK_ID, USER_ID);
        expect(result.clearedExisting).toBe(true);
        expect(result.mode).toBe('replace');
    });

    test('records failed names that cannot be resolved', async () => {
        jest.spyOn(resolver, 'resolveByName').mockResolvedValue({ kind: 'not_found' });

        const result = await importDeckFromList(
            USER_ID,
            DECK_ID,
            {
                text: '1 Not A Real Card Name',
                mode: 'merge',
            },
            resolver,
        );

        expect(result.imported).toHaveLength(0);
        expect(result.failed).toEqual([
            {
                line: 1,
                name: 'Not A Real Card Name',
                reason: 'not_found',
            },
        ]);
        expect(addCardToDeckForUser).not.toHaveBeenCalled();
    });

    test('records rate limit failures without stopping import', async () => {
        jest.spyOn(resolver, 'resolveByName')
            .mockResolvedValueOnce({ kind: 'rate_limit' })
            .mockResolvedValueOnce({ kind: 'unique', card: makeCard(SCRYFALL_PLAINS, 'Plains') });

        const result = await importDeckFromList(
            USER_ID,
            DECK_ID,
            {
                text: '1 Sol Ring\n1 Plains',
                mode: 'merge',
            },
            resolver,
        );

        expect(result.failed).toEqual([
            { line: 1, name: 'Sol Ring', reason: 'rate_limit' },
        ]);
        expect(result.imported).toHaveLength(1);
    });

    test('throws when deck is not found', async () => {
        (getByIdForUser as jest.Mock).mockResolvedValue(null);

        await expect(
            importDeckFromList(
                USER_ID,
                DECK_ID,
                { text: '1 Sol Ring', mode: 'merge' },
                resolver,
            ),
        ).rejects.toThrow('Deck not found');
    });
});
