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
    listCollectionEntriesForScryfall,
    updateAssignmentQuantity,
    type AssignmentRecord,
} from '../repositories/DeckCardAssignmentRepository';

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
}

export interface AssignCollectionEntryInput {
    collectionEntryId: string;
    quantity: number;
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

const loadAssignmentContext = async (
    userId: string,
    deckCard: { id: string; scryfallId: string; quantity: number },
    collectionEntryId: string,
    excludeAssignmentId?: string,
) => {
    const entry = await findCollectionEntryForUser(collectionEntryId, userId);
    if (!entry) {
        throw new Error('Collection entry not found');
    }
    if (entry.scryfallId !== deckCard.scryfallId) {
        throw new Error('Scryfall ID mismatch');
    }

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
            currentFilledOnSlot: ctx.currentFilled + ctx.existingOnSlot.quantity,
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

    const entries = await listCollectionEntriesForScryfall(userId, deckCard.scryfallId);
    const assignedTotals = await getAssignedTotalsByCollectionEntry(userId);

    return entries.map((entry) => {
        const assignedTotal = assignedTotals.get(entry.id) ?? 0;
        return {
            collectionEntryId: entry.id,
            condition: entry.condition,
            isFoil: entry.isFoil,
            entryQuantity: entry.quantity,
            assignedTotal,
            availableToAssign: Math.max(0, entry.quantity - assignedTotal),
        };
    });
};

export const applyAssignmentsToNewSlot = async (
    userId: string,
    deckCardId: string,
    deckCardQuantity: number,
    scryfallId: string,
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
        if (entry.scryfallId !== scryfallId) {
            throw new Error('Scryfall ID mismatch');
        }

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
