import {
    createAssignment,
    deleteAssignment,
    findAssignmentOnDeckCard,
    findCollectionEntryForUser,
    findDeckCardForUser,
    getAssignedTotalsByCollectionEntry,
    getAssignmentForUser,
    getAssignmentsForDeckCard,
    getFilledQuantityOnDeckCard,
    listCollectionEntriesForCardName,
    updateAssignmentQuantity,
    type AssignmentRecord,
    type CollectionEntryByNameRecord,
} from '../repositories/DeckCardAssignmentRepository';
import { getByIdForUserWithCards } from '../repositories/DeckRepository';
import { touchCollectionEntryUpdatedAt } from '../repositories/CollectionEntryRepository';
import { touchDeckUpdatedAt } from '../repositories/DeckRepository';
import { cardNamesMatch } from '../utils/cardNameMatch';

export interface DeckCardAssignmentItem {
    id: string;
    collectionEntryId: string;
    quantity: number;
    condition: string;
    isFoil: boolean;
}

export interface DeckCardFillStatus {
    quantity: number;
    filledQty: number;
    unfilledQty: number;
    assignments: DeckCardAssignmentItem[];
}

export interface CollectionEntryOption {
    collectionEntryId: string;
    condition: string;
    isFoil: boolean;
    entryQuantity: number;
    assignedTotal: number;
    availableToAssign: number;
    scryfallId: string;
    setCode: string | null;
    name: string | null;
    isExactPrinting: boolean;
}

export interface AssignCollectionEntryInput {
    collectionEntryId: string;
    quantity: number;
}

export interface AssignDeckByNameSummary {
    assignedSlots: number;
    assignedCopies: number;
    skippedNoCollection: number;
    skippedNoName: number;
}

export const buildDeckCardFillStatus = (
    deckCardQuantity: number,
    assignments: AssignmentRecord[],
): DeckCardFillStatus => {
    const filledQty = assignments.reduce((sum, a) => sum + a.quantity, 0);
    return {
        quantity: deckCardQuantity,
        filledQty,
        unfilledQty: Math.max(0, deckCardQuantity - filledQty),
        assignments: assignments.map((a) => ({
            id: a.id,
            collectionEntryId: a.collectionEntryId,
            quantity: a.quantity,
            condition: a.condition,
            isFoil: a.isFoil,
        })),
    };
};

export const assertPositiveQuantity = (quantity: number): void => {
    if (!Number.isInteger(quantity) || quantity <= 0) {
        throw new Error('quantity must be greater than 0');
    }
};

export const validateAssignmentQuantity = (params: {
    deckCardQuantity: number;
    currentFilledOnSlot: number;
    existingOnSlotForEntry: number;
    newQuantity: number;
    collectionEntryQuantity: number;
    assignedOnEntryTotal: number;
}): void => {
    const {
        deckCardQuantity,
        currentFilledOnSlot,
        existingOnSlotForEntry,
        newQuantity,
        collectionEntryQuantity,
        assignedOnEntryTotal,
    } = params;

    const filledAfter = currentFilledOnSlot - existingOnSlotForEntry + newQuantity;
    if (filledAfter > deckCardQuantity) {
        throw new Error('Exceeds deck slot quantity');
    }

    const assignedOnEntryAfter = assignedOnEntryTotal - existingOnSlotForEntry + newQuantity;
    if (assignedOnEntryAfter > collectionEntryQuantity) {
        throw new Error('Exceeds collection entry quantity');
    }
};

export const validateAssignmentsForNewSlot = (
    deckCardQuantity: number,
    assignments: AssignCollectionEntryInput[],
): void => {
    const total = assignments.reduce((sum, a) => sum + a.quantity, 0);
    if (total > deckCardQuantity) {
        throw new Error('Exceeds deck slot quantity');
    }
};

const assertEntryMatchesDeckCardName = (
    deckCardName: string | null,
    entryName: string | null,
): void => {
    if (!deckCardName || !cardNamesMatch(deckCardName, entryName)) {
        throw new Error('Card name mismatch');
    }
};

const buildOptionsFromEntries = (
    entries: CollectionEntryByNameRecord[],
    deckScryfallId: string,
    assignedTotals: Map<string, number>,
): CollectionEntryOption[] => {
    const options = entries.map((entry) => {
        const assignedTotal = assignedTotals.get(entry.id) ?? 0;
        return {
            collectionEntryId: entry.id,
            condition: entry.condition,
            isFoil: entry.isFoil,
            entryQuantity: entry.quantity,
            assignedTotal,
            availableToAssign: Math.max(0, entry.quantity - assignedTotal),
            scryfallId: entry.scryfallId,
            setCode: entry.setCode,
            name: entry.name,
            isExactPrinting: entry.scryfallId === deckScryfallId,
        };
    });

    options.sort((a, b) => {
        if (a.isExactPrinting !== b.isExactPrinting) {
            return a.isExactPrinting ? -1 : 1;
        }
        const setA = a.setCode ?? '';
        const setB = b.setCode ?? '';
        if (setA !== setB) return setA.localeCompare(setB);
        if (a.condition !== b.condition) return a.condition.localeCompare(b.condition);
        if (a.isFoil !== b.isFoil) return a.isFoil ? 1 : -1;
        return 0;
    });

    return options;
};

const loadAssignmentContext = async (
    userId: string,
    deckCard: { id: string; name: string | null; quantity: number },
    collectionEntryId: string,
    excludeAssignmentId?: string,
) => {
    const entry = await findCollectionEntryForUser(collectionEntryId, userId);
    if (!entry) {
        throw new Error('Collection entry not found');
    }
    assertEntryMatchesDeckCardName(deckCard.name, entry.name);

    const slotAssignments = await getAssignmentsForDeckCard(deckCard.id);
    const assignedTotals = await getAssignedTotalsByCollectionEntry(userId);

    const existingOnSlot = slotAssignments.find((a) => a.collectionEntryId === collectionEntryId);
    const existingOnSlotQty = existingOnSlot && existingOnSlot.id !== excludeAssignmentId
        ? existingOnSlot.quantity
        : 0;

    const assignedOnEntry = assignedTotals.get(collectionEntryId) ?? 0;
    const currentFilled = slotAssignments
        .filter((a) => a.id !== excludeAssignmentId)
        .reduce((sum, a) => sum + a.quantity, 0);

    return {
        entry,
        existingOnSlot,
        existingOnSlotQty,
        assignedOnEntry,
        currentFilled,
    };
};

export const assignCollectionEntry = async (
    userId: string,
    deckId: string,
    deckCardId: string,
    input: AssignCollectionEntryInput,
): Promise<DeckCardFillStatus> => {
    assertPositiveQuantity(input.quantity);

    const deckCard = await findDeckCardForUser(deckCardId, deckId, userId);
    if (!deckCard) {
        throw new Error('Deck card not found');
    }

    const ctx = await loadAssignmentContext(userId, deckCard, input.collectionEntryId);

    if (ctx.existingOnSlot) {
        const newQty = ctx.existingOnSlot.quantity + input.quantity;
        validateAssignmentQuantity({
            deckCardQuantity: deckCard.quantity,
            currentFilledOnSlot: ctx.currentFilled,
            existingOnSlotForEntry: ctx.existingOnSlot.quantity,
            newQuantity: newQty,
            collectionEntryQuantity: ctx.entry.quantity,
            assignedOnEntryTotal: ctx.assignedOnEntry,
        });
        await updateAssignmentQuantity(ctx.existingOnSlot.id, newQty);
    } else {
        validateAssignmentQuantity({
            deckCardQuantity: deckCard.quantity,
            currentFilledOnSlot: ctx.currentFilled,
            existingOnSlotForEntry: 0,
            newQuantity: input.quantity,
            collectionEntryQuantity: ctx.entry.quantity,
            assignedOnEntryTotal: ctx.assignedOnEntry,
        });
        await createAssignment(deckCardId, input.collectionEntryId, input.quantity);
    }

    const assignments = await getAssignmentsForDeckCard(deckCardId);
    await touchCollectionEntryUpdatedAt(input.collectionEntryId);
    await touchDeckUpdatedAt(deckId);
    return buildDeckCardFillStatus(deckCard.quantity, assignments);
};

export const updateAssignment = async (
    userId: string,
    deckId: string,
    deckCardId: string,
    assignmentId: string,
    quantity: number,
): Promise<DeckCardFillStatus> => {
    assertPositiveQuantity(quantity);

    const deckCard = await findDeckCardForUser(deckCardId, deckId, userId);
    if (!deckCard) {
        throw new Error('Deck card not found');
    }

    const assignment = await getAssignmentForUser(assignmentId, deckCardId, deckId, userId);
    if (!assignment) {
        throw new Error('Assignment not found');
    }

    const ctx = await loadAssignmentContext(
        userId,
        deckCard,
        assignment.collectionEntryId,
        assignmentId,
    );

    validateAssignmentQuantity({
        deckCardQuantity: deckCard.quantity,
        currentFilledOnSlot: ctx.currentFilled + assignment.quantity,
        existingOnSlotForEntry: assignment.quantity,
        newQuantity: quantity,
        collectionEntryQuantity: ctx.entry.quantity,
        assignedOnEntryTotal: ctx.assignedOnEntry,
    });

    await updateAssignmentQuantity(assignmentId, quantity);

    const assignments = await getAssignmentsForDeckCard(deckCardId);
    await touchCollectionEntryUpdatedAt(assignment.collectionEntryId);
    await touchDeckUpdatedAt(deckId);
    return buildDeckCardFillStatus(deckCard.quantity, assignments);
};

export const removeAssignment = async (
    userId: string,
    deckId: string,
    deckCardId: string,
    assignmentId: string,
): Promise<DeckCardFillStatus> => {
    const deckCard = await findDeckCardForUser(deckCardId, deckId, userId);
    if (!deckCard) {
        throw new Error('Deck card not found');
    }

    const assignment = await getAssignmentForUser(assignmentId, deckCardId, deckId, userId);
    if (!assignment) {
        throw new Error('Assignment not found');
    }

    await deleteAssignment(assignmentId);

    const assignments = await getAssignmentsForDeckCard(deckCardId);
    await touchCollectionEntryUpdatedAt(assignment.collectionEntryId);
    await touchDeckUpdatedAt(deckId);
    return buildDeckCardFillStatus(deckCard.quantity, assignments);
};

export const listCollectionOptionsForDeckCard = async (
    userId: string,
    deckId: string,
    deckCardId: string,
): Promise<CollectionEntryOption[]> => {
    const deckCard = await findDeckCardForUser(deckCardId, deckId, userId);
    if (!deckCard) {
        throw new Error('Deck card not found');
    }
    if (!deckCard.name) {
        throw new Error('Deck card has no name');
    }

    const entries = await listCollectionEntriesForCardName(userId, deckCard.name);
    const assignedTotals = await getAssignedTotalsByCollectionEntry(userId);

    return buildOptionsFromEntries(entries, deckCard.scryfallId, assignedTotals);
};

export const assignDeckFromCollectionByName = async (
    userId: string,
    deckId: string,
): Promise<AssignDeckByNameSummary> => {
    const deck = await getByIdForUserWithCards(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }

    let assignedSlots = 0;
    let assignedCopies = 0;
    let skippedNoCollection = 0;
    let skippedNoName = 0;

    for (const card of deck.cards) {
        const filledQty = card.assignments.reduce((sum, a) => sum + a.quantity, 0);
        let remaining = Math.max(0, card.quantity - filledQty);

        if (remaining <= 0) continue;

        if (!card.name) {
            skippedNoName += 1;
            continue;
        }

        let slotAssigned = 0;

        while (remaining > 0) {
            const options = await listCollectionOptionsForDeckCard(userId, deckId, card.id);
            const next = options.find((o) => o.availableToAssign > 0);
            if (!next) break;

            const qty = Math.min(remaining, next.availableToAssign);
            await assignCollectionEntry(userId, deckId, card.id, {
                collectionEntryId: next.collectionEntryId,
                quantity: qty,
            });
            slotAssigned += qty;
            remaining -= qty;
        }

        if (slotAssigned > 0) {
            assignedSlots += 1;
            assignedCopies += slotAssigned;
        } else {
            skippedNoCollection += 1;
        }
    }

    await touchDeckUpdatedAt(deckId);

    return {
        assignedSlots,
        assignedCopies,
        skippedNoCollection,
        skippedNoName,
    };
};

export const applyAssignmentsToNewSlot = async (
    userId: string,
    deckCardId: string,
    deckCardQuantity: number,
    deckCardName: string | null,
    assignments: AssignCollectionEntryInput[],
): Promise<void> => {
    if (assignments.length === 0) {
        return;
    }

    validateAssignmentsForNewSlot(deckCardQuantity, assignments);

    const assignedTotals = await getAssignedTotalsByCollectionEntry(userId);
    let filledOnSlot = 0;

    for (const input of assignments) {
        assertPositiveQuantity(input.quantity);

        const entry = await findCollectionEntryForUser(input.collectionEntryId, userId);
        if (!entry) {
            throw new Error('Collection entry not found');
        }
        assertEntryMatchesDeckCardName(deckCardName, entry.name);

        const assignedOnEntry = assignedTotals.get(input.collectionEntryId) ?? 0;
        validateAssignmentQuantity({
            deckCardQuantity,
            currentFilledOnSlot: filledOnSlot,
            existingOnSlotForEntry: 0,
            newQuantity: input.quantity,
            collectionEntryQuantity: entry.quantity,
            assignedOnEntryTotal: assignedOnEntry,
        });

        await createAssignment(deckCardId, input.collectionEntryId, input.quantity);
        filledOnSlot += input.quantity;
        assignedTotals.set(input.collectionEntryId, assignedOnEntry + input.quantity);
    }
};

export const getFillStatusForDeckCard = async (
    deckCardId: string,
    deckCardQuantity: number,
): Promise<DeckCardFillStatus> => {
    const assignments = await getAssignmentsForDeckCard(deckCardId);
    return buildDeckCardFillStatus(deckCardQuantity, assignments);
};

export const assertDeckCardQuantityCanDecrease = async (
    deckCardId: string,
    newQuantity: number,
): Promise<void> => {
    const filled = await getFilledQuantityOnDeckCard(deckCardId);
    if (newQuantity < filled) {
        throw new Error('Cannot reduce deck card below assigned quantity');
    }
};
