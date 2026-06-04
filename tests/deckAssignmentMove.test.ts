jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    findDeckCardForUser: jest.fn(),
    findCollectionEntryForUser: jest.fn(),
    getAssignmentsForDeckCard: jest.fn(),
    getAssignedTotalsByCollectionEntry: jest.fn(),
    listCollectionEntriesForCardName: jest.fn(),
    listAssignmentsForCollectionEntry: jest.fn(),
    reclaimCollectionEntryQuantity: jest.fn(),
    createAssignment: jest.fn(),
    updateAssignmentQuantity: jest.fn(),
    touchCollectionEntryUpdatedAt: jest.fn(),
}));

jest.mock('../src/backend/repositories/CollectionEntryRepository', () => ({
    touchCollectionEntryUpdatedAt: jest.fn(),
}));

jest.mock('../src/backend/repositories/DeckRepository', () => ({
    touchDeckUpdatedAt: jest.fn(),
}));

import {
    assignCollectionEntry,
    listCollectionOptionsForDeckCard,
} from '../src/backend/services/DeckCardAssignmentService';
import {
    findDeckCardForUser,
    findCollectionEntryForUser,
    getAssignmentsForDeckCard,
    getAssignedTotalsByCollectionEntry,
    listCollectionEntriesForCardName,
    listAssignmentsForCollectionEntry,
    reclaimCollectionEntryQuantity,
    createAssignment,
} from '../src/backend/repositories/DeckCardAssignmentRepository';
import { touchDeckUpdatedAt } from '../src/backend/repositories/DeckRepository';

const USER_ID = 'user-1';
const DECK_A = 'deck-a';
const DECK_B = 'deck-b';
const DECK_CARD_A = 'deck-card-a';
const DECK_CARD_B = 'deck-card-b';
const ENTRY_ID = 'entry-1';
const SCRYFALL_A = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

describe('Deck assignment move between decks', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (reclaimCollectionEntryQuantity as jest.Mock).mockResolvedValue({
            reclaimed: 4,
            affectedDeckIds: [DECK_A],
        });
        (createAssignment as jest.Mock).mockResolvedValue({
            id: 'assign-new',
            deckCardId: DECK_CARD_B,
            collectionEntryId: ENTRY_ID,
            quantity: 4,
            condition: 'NM',
            isFoil: false,
        });
        (touchDeckUpdatedAt as jest.Mock).mockResolvedValue(undefined);
    });

    describe('listCollectionOptionsForDeckCard', () => {
        test('shows full entry qty as available when assigned only on another deck', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_B,
                deckId: DECK_B,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                board: 'main',
            });
            (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
            (listCollectionEntriesForCardName as jest.Mock).mockResolvedValue([
                {
                    id: ENTRY_ID,
                    scryfallId: SCRYFALL_A,
                    name: 'Lightning Bolt',
                    setCode: 'M21',
                    quantity: 4,
                    condition: 'NM',
                    isFoil: false,
                },
            ]);
            (getAssignedTotalsByCollectionEntry as jest.Mock).mockResolvedValue(
                new Map([[ENTRY_ID, 4]]),
            );
            (listAssignmentsForCollectionEntry as jest.Mock).mockResolvedValue([
                {
                    id: 'assign-a',
                    deckCardId: DECK_CARD_A,
                    deckId: DECK_A,
                    deckName: 'Burn',
                    quantity: 4,
                },
            ]);

            const options = await listCollectionOptionsForDeckCard(
                USER_ID,
                DECK_B,
                DECK_CARD_B,
            );

            expect(options[0].availableToAssign).toBe(4);
            expect(options[0].assignedElsewhere).toBe(4);
            expect(options[0].assignedOnSlot).toBe(0);
            expect(options[0].transferSources).toEqual([
                { deckId: DECK_A, deckName: 'Burn', quantity: 4 },
            ]);
        });
    });

    describe('assignCollectionEntry', () => {
        test('reclaims from other deck before creating assignment', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_B,
                deckId: DECK_B,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_ID,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                condition: 'NM',
                isFoil: false,
            });
            (getAssignmentsForDeckCard as jest.Mock)
                .mockResolvedValueOnce([])
                .mockResolvedValueOnce([
                    {
                        id: 'assign-new',
                        deckCardId: DECK_CARD_B,
                        collectionEntryId: ENTRY_ID,
                        quantity: 4,
                        condition: 'NM',
                        isFoil: false,
                    },
                ]);
            (getAssignedTotalsByCollectionEntry as jest.Mock)
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 4]]))
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 0]]))
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 0]]));

            await assignCollectionEntry(USER_ID, DECK_B, DECK_CARD_B, {
                collectionEntryId: ENTRY_ID,
                quantity: 4,
            });

            expect(reclaimCollectionEntryQuantity).toHaveBeenCalledWith(
                USER_ID,
                ENTRY_ID,
                4,
                DECK_CARD_B,
            );
            expect(touchDeckUpdatedAt).toHaveBeenCalledWith(DECK_A);
            expect(touchDeckUpdatedAt).toHaveBeenCalledWith(DECK_B);
            expect(createAssignment).toHaveBeenCalledWith(DECK_CARD_B, ENTRY_ID, 4);
        });
    });
});
