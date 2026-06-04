jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    findDeckCardForUser: jest.fn(),
    findCollectionEntryForUser: jest.fn(),
    getAssignmentsForDeckCard: jest.fn(),
    getAssignedTotalsByCollectionEntry: jest.fn(),
    listCollectionEntriesForCardName: jest.fn(),
    createAssignment: jest.fn(),
    findAssignmentOnDeckCard: jest.fn(),
    updateAssignmentQuantity: jest.fn(),
    touchCollectionEntryUpdatedAt: jest.fn(),
}));

jest.mock('../src/backend/repositories/DeckRepository', () => ({
    getByIdForUserWithCards: jest.fn(),
    touchDeckUpdatedAt: jest.fn(),
}));

jest.mock('../src/backend/repositories/CollectionEntryRepository', () => ({
    touchCollectionEntryUpdatedAt: jest.fn(),
}));

import {
    assignCollectionEntry,
    assignDeckFromCollectionByName,
    listCollectionOptionsForDeckCard,
} from '../src/backend/services/DeckCardAssignmentService';
import {
    findDeckCardForUser,
    findCollectionEntryForUser,
    getAssignmentsForDeckCard,
    getAssignedTotalsByCollectionEntry,
    listCollectionEntriesForCardName,
    createAssignment,
    findAssignmentOnDeckCard,
} from '../src/backend/repositories/DeckCardAssignmentRepository';
import { getByIdForUserWithCards, touchDeckUpdatedAt } from '../src/backend/repositories/DeckRepository';

const USER_ID = 'user-1';
const DECK_ID = 'deck-1';
const DECK_CARD_ID = 'deck-card-1';
const ENTRY_A = 'entry-a';
const ENTRY_B = 'entry-b';
const SCRYFALL_A = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const SCRYFALL_B = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

describe('DeckCardAssignment by name', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (getAssignedTotalsByCollectionEntry as jest.Mock).mockResolvedValue(new Map());
        (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
        (findAssignmentOnDeckCard as jest.Mock).mockResolvedValue(null);
        (createAssignment as jest.Mock).mockResolvedValue({
            id: 'assign-1',
            deckCardId: DECK_CARD_ID,
            collectionEntryId: ENTRY_B,
            quantity: 1,
            condition: 'NM',
            isFoil: false,
        });
    });

    describe('listCollectionOptionsForDeckCard', () => {
        test('returns options for same name across printings', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_ID,
                deckId: DECK_ID,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                board: 'main',
            });
            (listCollectionEntriesForCardName as jest.Mock).mockResolvedValue([
                {
                    id: ENTRY_A,
                    scryfallId: SCRYFALL_A,
                    name: 'Lightning Bolt',
                    setCode: 'M21',
                    quantity: 2,
                    condition: 'NM',
                    isFoil: false,
                },
                {
                    id: ENTRY_B,
                    scryfallId: SCRYFALL_B,
                    name: 'Lightning Bolt',
                    setCode: 'LEA',
                    quantity: 3,
                    condition: 'LP',
                    isFoil: false,
                },
            ]);
            (getAssignedTotalsByCollectionEntry as jest.Mock).mockResolvedValue(
                new Map([[ENTRY_A, 2]]),
            );

            const options = await listCollectionOptionsForDeckCard(
                USER_ID,
                DECK_ID,
                DECK_CARD_ID,
            );

            expect(options).toHaveLength(2);
            expect(options[0].isExactPrinting).toBe(true);
            expect(options[0].availableToAssign).toBe(0);
            expect(options[1].isExactPrinting).toBe(false);
            expect(options[1].setCode).toBe('LEA');
            expect(options[1].availableToAssign).toBe(3);
        });
    });

    describe('assignCollectionEntry', () => {
        test('allows assignment when names match but scryfall ids differ', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_ID,
                deckId: DECK_ID,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_B,
                scryfallId: SCRYFALL_B,
                name: 'Lightning Bolt',
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            });
            (getAssignmentsForDeckCard as jest.Mock)
                .mockResolvedValueOnce([])
                .mockResolvedValueOnce([
                    {
                        id: 'assign-1',
                        deckCardId: DECK_CARD_ID,
                        collectionEntryId: ENTRY_B,
                        quantity: 1,
                        condition: 'NM',
                        isFoil: false,
                    },
                ]);

            const fillStatus = await assignCollectionEntry(USER_ID, DECK_ID, DECK_CARD_ID, {
                collectionEntryId: ENTRY_B,
                quantity: 1,
            });

            expect(fillStatus.filledQty).toBe(1);
            expect(createAssignment).toHaveBeenCalledWith(DECK_CARD_ID, ENTRY_B, 1);
        });

        test('rejects assignment when names differ', async () => {
            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_ID,
                deckId: DECK_ID,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 4,
                board: 'main',
            });
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_B,
                scryfallId: SCRYFALL_B,
                name: 'Counterspell',
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            });

            await expect(
                assignCollectionEntry(USER_ID, DECK_ID, DECK_CARD_ID, {
                    collectionEntryId: ENTRY_B,
                    quantity: 1,
                }),
            ).rejects.toThrow('Card name mismatch');
        });
    });

    describe('assignDeckFromCollectionByName', () => {
        test('fills unfilled slots from name-matched collection', async () => {
            (getByIdForUserWithCards as jest.Mock).mockResolvedValue({
                id: DECK_ID,
                cards: [
                    {
                        id: DECK_CARD_ID,
                        scryfallId: SCRYFALL_A,
                        name: 'Lightning Bolt',
                        quantity: 2,
                        board: 'main',
                        assignments: [],
                    },
                ],
            });

            (findDeckCardForUser as jest.Mock).mockResolvedValue({
                id: DECK_CARD_ID,
                deckId: DECK_ID,
                scryfallId: SCRYFALL_A,
                name: 'Lightning Bolt',
                quantity: 2,
                board: 'main',
            });

            (listCollectionEntriesForCardName as jest.Mock).mockResolvedValue([
                {
                    id: ENTRY_B,
                    scryfallId: SCRYFALL_B,
                    name: 'Lightning Bolt',
                    setCode: 'LEA',
                    quantity: 2,
                    condition: 'NM',
                    isFoil: false,
                },
            ]);

            (getAssignedTotalsByCollectionEntry as jest.Mock).mockResolvedValue(new Map());

            (getAssignmentsForDeckCard as jest.Mock).mockResolvedValue([]);
            (findCollectionEntryForUser as jest.Mock).mockResolvedValue({
                id: ENTRY_B,
                scryfallId: SCRYFALL_B,
                name: 'Lightning Bolt',
                quantity: 2,
                condition: 'NM',
                isFoil: false,
            });

            const summary = await assignDeckFromCollectionByName(USER_ID, DECK_ID);

            expect(summary.assignedSlots).toBe(1);
            expect(summary.assignedCopies).toBe(2);
            expect(summary.skippedNoCollection).toBe(0);
            expect(touchDeckUpdatedAt).toHaveBeenCalledWith(DECK_ID);
        });
    });
});
