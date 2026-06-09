jest.mock('../src/backend/repositories/DeckRepository', () => ({
    listByUser: jest.fn(),
    listDeckCardSummariesForUser: jest.fn(),
}));

jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    getOwnedCardNamesForUser: jest.fn(),
}));

jest.mock('../src/backend/services/DeckFormatWarningService', () => ({
    getWarningsForDeckCards: jest.fn(),
}));

import { listDecks } from '../src/backend/services/DeckService';
import { listByUser, listDeckCardSummariesForUser } from '../src/backend/repositories/DeckRepository';
import { getOwnedCardNamesForUser } from '../src/backend/repositories/DeckCardAssignmentRepository';
import { getWarningsForDeckCards } from '../src/backend/services/DeckFormatWarningService';

const USER_ID = 'user-1';
const DECK_ID = 'deck-1';
const NOW = new Date('2024-01-01T00:00:00.000Z');

describe('listDecks live status', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (getWarningsForDeckCards as jest.Mock).mockResolvedValue(new Map());
        (getOwnedCardNamesForUser as jest.Mock).mockResolvedValue(new Set(['lightning bolt']));
    });

    test('includes isFormatValid and isFullyAssigned on list items', async () => {
        (listByUser as jest.Mock).mockResolvedValue([
            {
                id: DECK_ID,
                userId: USER_ID,
                name: 'Burn',
                format: 'Modern',
                description: null,
                isValid: null,
                lastValidatedAt: null,
                createdAt: NOW,
                updatedAt: NOW,
            },
        ]);
        (listDeckCardSummariesForUser as jest.Mock).mockResolvedValue([
            {
                deckId: DECK_ID,
                board: 'main',
                quantity: 4,
                scryfallId: 'scry-1',
                name: 'Lightning Bolt',
                typeLine: 'Instant',
                filledQty: 4,
            },
        ]);

        const decks = await listDecks(USER_ID);

        expect(decks).toHaveLength(1);
        expect(decks[0].isFormatValid).toBe(false);
        expect(decks[0].isFullyAssigned).toBe(true);
    });
});
