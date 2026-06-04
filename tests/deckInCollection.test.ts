jest.mock('../src/backend/repositories/DeckRepository', () => ({
    getByIdForUserWithCards: jest.fn(),
}));

jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    getOwnedCardNamesForUser: jest.fn(),
}));

jest.mock('../src/backend/services/DeckFormatWarningService', () => ({
    getWarningsForDeckCards: jest.fn(),
}));

import { getDeckDetails } from '../src/backend/services/DeckService';
import { getByIdForUserWithCards } from '../src/backend/repositories/DeckRepository';
import { getOwnedCardNamesForUser } from '../src/backend/repositories/DeckCardAssignmentRepository';
import { getWarningsForDeckCards } from '../src/backend/services/DeckFormatWarningService';

const USER_ID = 'user-1';
const DECK_ID = 'deck-1';

describe('Deck card inCollection', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (getWarningsForDeckCards as jest.Mock).mockResolvedValue(new Map());
    });

    test('marks cards whose names exist in collection', async () => {
        (getByIdForUserWithCards as jest.Mock).mockResolvedValue({
            id: DECK_ID,
            userId: USER_ID,
            name: 'Test',
            format: 'Modern',
            description: null,
            isValid: null,
            lastValidatedAt: null,
            createdAt: new Date(),
            updatedAt: new Date(),
            cards: [
                {
                    id: 'dc-1',
                    scryfallId: 'a',
                    quantity: 4,
                    board: 'main',
                    name: 'Lightning Bolt',
                    setCode: 'M21',
                    typeLine: 'Instant',
                    imageUrl: null,
                    imageUrlHiRes: null,
                    assignments: [],
                },
                {
                    id: 'dc-2',
                    scryfallId: 'b',
                    quantity: 1,
                    board: 'main',
                    name: 'Counterspell',
                    setCode: null,
                    typeLine: 'Instant',
                    imageUrl: null,
                    imageUrlHiRes: null,
                    assignments: [],
                },
            ],
        });
        (getOwnedCardNamesForUser as jest.Mock).mockResolvedValue(
            new Set(['lightning bolt']),
        );

        const deck = await getDeckDetails(USER_ID, DECK_ID);

        expect(getOwnedCardNamesForUser).toHaveBeenCalledWith(USER_ID, [
            'Lightning Bolt',
            'Counterspell',
        ]);
        expect(deck.cards[0].inCollection).toBe(true);
        expect(deck.cards[1].inCollection).toBe(false);
    });
});
