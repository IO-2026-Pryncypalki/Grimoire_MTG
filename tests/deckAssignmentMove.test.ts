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
        test('shows zero free copies but assignable via transfer when assigned elsewhere', async () => {
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

            expect(options[0].availableToAssign).toBe(0);
            expect(options[0].assignableToSlot).toBe(4);
            expect(options[0].assignedElsewhere).toBe(4);
            expect(options[0].assignedOnSlot).toBe(0);
            expect(options[0].transferSources).toEqual([
                { deckId: DECK_A, deckName: 'Burn', quantity: 4 },
            ]);
        });

        test('single copy fully assigned elsewhere has no free copies but can transfer', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_B,
                deckId: DECK_B,
                scryfallId: SCRYFALL_A,
                name: 'Wise Mothman',
                quantity: 1,
                board: 'main',
            });
            (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
            (listCollectionEntriesForCardName as jest.Mock).mockResolvedValue([
                {
                    id: ENTRY_ID,
                    scryfallId: SCRYFALL_A,
                    name: 'Wise Mothman',
                    setCode: 'DSK',
                    quantity: 1,
                    condition: 'NM',
                    isFoil: false,
                },
            ]);
            (getAssignedTotalsByCollectionEntry as jest.Mock).mockResolvedValue(
                new Map([[ENTRY_ID, 1]]),
            );
            (listAssignmentsForCollectionEntry as jest.Mock).mockResolvedValue([
                {
                    id: 'assign-a',
                    deckCardId: DECK_CARD_A,
                    deckId: DECK_A,
                    deckName: 'Deck A',
                    quantity: 1,
                },
            ]);

            const options = await listCollectionOptionsForDeckCard(
                USER_ID,
                DECK_B,
                DECK_CARD_B,
            );

            expect(options[0].availableToAssign).toBe(0);
            expect(options[0].assignableToSlot).toBe(1);
            expect(options[0].assignedElsewhere).toBe(1);
        });
    });

    describe('assignCollectionEntry', () => {
        test('entry with qty=2 can be split 1+1 across two separate deck slots', async () => {
            // First call: assign 1 copy to Deck A
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_A,
                deckId: DECK_A,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 1,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_ID,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            });
            (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
            (getAssignedTotalsByCollectionEntry as jest.Mock)
                .mockResolvedValueOnce(new Map()) // assignedOnEntry before ensureEntryCapacity
                .mockResolvedValueOnce(new Map()); // re-fetch after ensureEntryCapacity
            (reclaimCollectionEntryQuantity as jest.Mock).mockResolvedValue({
                reclaimed: 0,
                affectedDeckIds: [],
            });
            (createAssignment as jest.Mock).mockResolvedValue({
                id: 'assign-deck-a',
                deckCardId: DECK_CARD_A,
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            await assignCollectionEntry(USER_ID, DECK_A, DECK_CARD_A, {
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            expect(reclaimCollectionEntryQuantity).not.toHaveBeenCalled();
            expect(createAssignment).toHaveBeenCalledWith(DECK_CARD_A, ENTRY_ID, 1);

            jest.clearAllMocks();
            (touchDeckUpdatedAt as jest.Mock).mockResolvedValue(undefined);
            (reclaimCollectionEntryQuantity as jest.Mock).mockResolvedValue({
                reclaimed: 0,
                affectedDeckIds: [],
            });
            (createAssignment as jest.Mock).mockResolvedValue({
                id: 'assign-deck-b',
                deckCardId: DECK_CARD_B,
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            // Second call: assign the other copy to Deck B — no reclaim needed (1+1 = 2 = entry qty)
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_B,
                deckId: DECK_B,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 1,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_ID,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            });
            (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
            (getAssignedTotalsByCollectionEntry as jest.Mock)
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 1]])) // 1 already assigned (to Deck A)
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 1]])); // re-fetch after ensureEntryCapacity

            await assignCollectionEntry(USER_ID, DECK_B, DECK_CARD_B, {
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            expect(reclaimCollectionEntryQuantity).not.toHaveBeenCalled();
            expect(createAssignment).toHaveBeenCalledWith(DECK_CARD_B, ENTRY_ID, 1);
        });

        test('entry with qty=1 reclaims from previous deck when assigned to a new deck', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_B,
                deckId: DECK_B,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 1,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_ID,
                scryfallId: SCRYFALL_A,
                name: 'Command Tower',
                quantity: 1,
                condition: 'NM',
                isFoil: false,
            });
            (getAssignmentsForDeckCard as jest.Mock)
                .mockResolvedValueOnce([])
                .mockResolvedValueOnce([
                    { id: 'assign-deck-b', deckCardId: DECK_CARD_B, collectionEntryId: ENTRY_ID, quantity: 1 },
                ]);
            (getAssignedTotalsByCollectionEntry as jest.Mock)
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 1]])) // 1 already assigned elsewhere
                .mockResolvedValueOnce(new Map([[ENTRY_ID, 0]])); // after reclaim
            (reclaimCollectionEntryQuantity as jest.Mock).mockResolvedValue({
                reclaimed: 1,
                affectedDeckIds: [DECK_A],
            });
            (createAssignment as jest.Mock).mockResolvedValue({
                id: 'assign-deck-b',
                deckCardId: DECK_CARD_B,
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            await assignCollectionEntry(USER_ID, DECK_B, DECK_CARD_B, {
                collectionEntryId: ENTRY_ID,
                quantity: 1,
            });

            // Single copy must be reclaimed from Deck A before being placed in Deck B
            expect(reclaimCollectionEntryQuantity).toHaveBeenCalledWith(USER_ID, ENTRY_ID, 1, DECK_CARD_B);
            expect(createAssignment).toHaveBeenCalledWith(DECK_CARD_B, ENTRY_ID, 1);
        });

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
