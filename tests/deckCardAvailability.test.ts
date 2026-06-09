jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    getOwnedQuantityByCardName: jest.fn(),
    getDeckQuantityByCardName: jest.fn(),
    listDecksUsingCardName: jest.fn(),
}));

import {
    assertCanAddCardQuantityByName,
    EXCEEDS_OWNED_COLLECTION_QUANTITY,
    getCardAvailabilityByName,
} from '../src/backend/services/deckCardAvailability';
import {
    getDeckQuantityByCardName,
    getOwnedQuantityByCardName,
    listDecksUsingCardName,
} from '../src/backend/repositories/DeckCardAssignmentRepository';

const USER_ID = 'user-1';

describe('deckCardAvailability', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('assertCanAddCardQuantityByName', () => {
        test('allows add when card is not in collection', async () => {
            (getOwnedQuantityByCardName as jest.Mock).mockResolvedValue(0);

            await expect(
                assertCanAddCardQuantityByName(USER_ID, 'Command Tower', 1),
            ).resolves.toBeUndefined();

            expect(getDeckQuantityByCardName).not.toHaveBeenCalled();
        });

        test('allows add when owned copies remain', async () => {
            (getOwnedQuantityByCardName as jest.Mock).mockResolvedValue(2);
            (getDeckQuantityByCardName as jest.Mock).mockResolvedValue(1);

            await expect(
                assertCanAddCardQuantityByName(USER_ID, 'Command Tower', 1),
            ).resolves.toBeUndefined();
        });

        test('blocks add when all owned copies are already in decks', async () => {
            (getOwnedQuantityByCardName as jest.Mock).mockResolvedValue(1);
            (getDeckQuantityByCardName as jest.Mock).mockResolvedValue(1);

            await expect(
                assertCanAddCardQuantityByName(USER_ID, 'Command Tower', 1),
            ).rejects.toThrow(EXCEEDS_OWNED_COLLECTION_QUANTITY);
        });

        test('blocks merge in same deck when it would exceed owned quantity', async () => {
            (getOwnedQuantityByCardName as jest.Mock).mockResolvedValue(2);
            (getDeckQuantityByCardName as jest.Mock).mockResolvedValue(2);

            await expect(
                assertCanAddCardQuantityByName(USER_ID, 'Command Tower', 1),
            ).rejects.toThrow(EXCEEDS_OWNED_COLLECTION_QUANTITY);
        });
    });

    describe('getCardAvailabilityByName', () => {
        test('returns availability summary', async () => {
            (getOwnedQuantityByCardName as jest.Mock).mockResolvedValue(3);
            (getDeckQuantityByCardName as jest.Mock).mockResolvedValue(2);
            (listDecksUsingCardName as jest.Mock).mockResolvedValue([
                { deckId: 'd1', deckName: 'Deck A', deckCardId: 'dc1', quantity: 2 },
            ]);

            const result = await getCardAvailabilityByName(USER_ID, 'Command Tower');

            expect(result).toEqual({
                ownedQty: 3,
                inDecksQty: 2,
                availableToAdd: 1,
                decksUsing: [
                    { deckId: 'd1', deckName: 'Deck A', deckCardId: 'dc1', quantity: 2 },
                ],
            });
        });
    });
});
