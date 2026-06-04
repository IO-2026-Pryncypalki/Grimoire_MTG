import {
    addCardToDeckForUser,
    createForUser,
    deleteForUser,
    getByIdForUser,
    getByIdForUserWithCards,
    listByUser,
    removeCardFromDeckForUser,
    updateForUser,
    type CreateDeckData,
    type DeckBoard,
    type DeckCardRecord,
    type DeckFormat,
    type DeckRecord,
    type UpdateDeckData,
} from '../repositories/DeckRepository';
import { getOwnedCardNamesForUser } from '../repositories/DeckCardAssignmentRepository';
import {
    assignCollectionEntry,
    buildDeckCardFillStatus,
    type AssignCollectionEntryInput,
    type DeckCardFillStatus,
} from './DeckCardAssignmentService';
import { normalizeCardName } from '../utils/cardNameMatch';
import { ensureCardInDb } from './CardService';
import {
    getWarningForCard,
    getWarningsForDeckCards,
    type FormatWarningDto,
} from './DeckFormatWarningService';

export type { DeckCardFillStatus, AssignCollectionEntryInput, FormatWarningDto };

export interface DeckListItem {
    id: string;
    name: string;
    format: DeckFormat;
    description: string | null;
    isValid: boolean | null;
    lastValidatedAt: string | null;
    createdAt: string;
    updatedAt: string;
}

export interface CreateDeckInput {
    name: string;
    format?: DeckFormat;
    description?: string | null;
}

export interface UpdateDeckInput {
    name?: string;
    format?: DeckFormat;
    description?: string | null;
    isValid?: boolean | null;
    lastValidatedAt?: string | null;
}

export interface DeckCardItem {
    id: string;
    scryfallId: string;
    quantity: number;
    board: DeckBoard;
    name: string | null;
    setCode: string | null;
    typeLine: string | null;
    imageUrl: string | null;
    imageUrlHiRes: string | null;
    inCollection: boolean;
    fillStatus: DeckCardFillStatus;
    formatWarning: FormatWarningDto | null;
}

export interface DeckDetails extends DeckListItem {
    cards: DeckCardItem[];
}

export interface AddDeckCardInput {
    scryfallId: string;
    quantity?: number;
    board?: DeckBoard;
    assignments?: AssignCollectionEntryInput[];
}

export interface RemoveDeckCardInput {
    board?: DeckBoard;
    quantity?: number;
}

export interface RemoveDeckCardResult {
    removed: boolean;
    card?: DeckCardItem;
}

export interface AddDeckCardResult {
    card: DeckCardItem;
    formatWarning: FormatWarningDto | null;
}

const isCardInCollection = (name: string | null, ownedNames: Set<string>): boolean => {
    const normalized = normalizeCardName(name);
    return normalized.length > 0 && ownedNames.has(normalized);
};

const toDeckCardItem = (
    card: DeckCardRecord,
    formatWarning: FormatWarningDto | null = null,
    ownedNames: Set<string> = new Set(),
): DeckCardItem => ({
    id: card.id,
    scryfallId: card.scryfallId,
    quantity: card.quantity,
    board: card.board,
    name: card.name,
    setCode: card.setCode,
    typeLine: card.typeLine,
    imageUrl: card.imageUrl,
    imageUrlHiRes: card.imageUrlHiRes,
    inCollection: isCardInCollection(card.name, ownedNames),
    fillStatus: buildDeckCardFillStatus(card.quantity, card.assignments.map((a) => ({
        id: a.id,
        deckCardId: card.id,
        collectionEntryId: a.collectionEntryId,
        quantity: a.quantity,
        condition: a.condition,
        isFoil: a.isFoil,
    })) as Parameters<typeof buildDeckCardFillStatus>[1]),
    formatWarning,
});

const toDeckListItem = (deck: DeckRecord): DeckListItem => ({
    id: deck.id,
    name: deck.name,
    format: deck.format,
    description: deck.description,
    isValid: deck.isValid,
    lastValidatedAt: deck.lastValidatedAt ? deck.lastValidatedAt.toISOString() : null,
    createdAt: deck.createdAt.toISOString(),
    updatedAt: deck.updatedAt.toISOString(),
});

const assertNonEmptyName = (name: string): void => {
    if (name.trim().length === 0) {
        throw new Error('Deck name must not be empty');
    }
};

const assertPositiveQuantity = (quantity: number): void => {
    if (!Number.isInteger(quantity) || quantity <= 0) {
        throw new Error('quantity must be greater than 0');
    }
};

const parseLastValidatedAt = (value: string | null | undefined): Date | null | undefined => {
    if (value === undefined) {
        return undefined;
    }
    if (value === null) {
        return null;
    }

    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
        throw new Error('Invalid lastValidatedAt date');
    }
    return date;
};

export const listDecks = async (userId: string): Promise<DeckListItem[]> => {
    const decks = await listByUser(userId);
    return decks.map(toDeckListItem);
};

export const getDeck = async (userId: string, deckId: string): Promise<DeckListItem> => {
    const deck = await getByIdForUser(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }
    return toDeckListItem(deck);
};

export const getDeckDetails = async (userId: string, deckId: string): Promise<DeckDetails> => {
    const deck = await getByIdForUserWithCards(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }

    const { cards, ...deckMeta } = deck;
    const warnings = await getWarningsForDeckCards(
        cards.map((card) => card.scryfallId),
        deckMeta.format,
    );
    const ownedNames = await getOwnedCardNamesForUser(
        userId,
        cards.map((card) => card.name).filter((name): name is string => name != null),
    );

    return {
        ...toDeckListItem(deckMeta),
        cards: cards.map((card) =>
            toDeckCardItem(card, warnings.get(card.scryfallId) ?? null, ownedNames),
        ),
    };
};

export const createDeck = async (userId: string, input: CreateDeckInput): Promise<DeckListItem> => {
    assertNonEmptyName(input.name);

    const payload: CreateDeckData = {
        name: input.name.trim(),
        format: input.format ?? 'Custom',
        description: input.description ?? null,
    };

    const deck = await createForUser(userId, payload);
    return toDeckListItem(deck);
};

export const updateDeck = async (
    userId: string,
    deckId: string,
    input: UpdateDeckInput,
): Promise<DeckListItem> => {
    const patch: UpdateDeckData = {};

    if (input.name !== undefined) {
        assertNonEmptyName(input.name);
        patch.name = input.name.trim();
    }
    if (input.format !== undefined) {
        patch.format = input.format;
    }
    if (input.description !== undefined) {
        patch.description = input.description;
    }
    if (input.isValid !== undefined) {
        patch.isValid = input.isValid;
    }

    const lastValidatedAt = parseLastValidatedAt(input.lastValidatedAt);
    if (lastValidatedAt !== undefined) {
        patch.lastValidatedAt = lastValidatedAt;
    }

    const deck = await updateForUser(deckId, userId, patch);
    if (!deck) {
        throw new Error('Deck not found');
    }

    return toDeckListItem(deck);
};

export const removeDeck = async (userId: string, deckId: string): Promise<void> => {
    const deleted = await deleteForUser(deckId, userId);
    if (!deleted) {
        throw new Error('Deck not found');
    }
};

export const addCardToDeck = async (
    userId: string,
    deckId: string,
    input: AddDeckCardInput,
): Promise<AddDeckCardResult> => {
    const quantity = input.quantity ?? 1;
    assertPositiveQuantity(quantity);

    const deckMeta = await getByIdForUser(deckId, userId);
    if (!deckMeta) {
        throw new Error('Deck not found');
    }

    await ensureCardInDb(input.scryfallId);

    const card = await addCardToDeckForUser(deckId, userId, {
        scryfallId: input.scryfallId,
        quantity,
        board: input.board ?? 'main',
    });

    if (input.assignments && input.assignments.length > 0) {
        for (const assignment of input.assignments) {
            await assignCollectionEntry(userId, deckId, card.id, assignment);
        }
    }

    const deck = await getByIdForUserWithCards(deckId, userId);
    const updatedCard = deck?.cards.find((c) => c.id === card.id);
    const formatWarning = await getWarningForCard(input.scryfallId, deckMeta.format);
    const cardRecord = updatedCard ?? { ...card, assignments: [] };
    const ownedNames = await getOwnedCardNamesForUser(
        userId,
        cardRecord.name ? [cardRecord.name] : [],
    );
    const deckCardItem = toDeckCardItem(cardRecord, formatWarning, ownedNames);

    return {
        card: deckCardItem,
        formatWarning,
    };
};

export const removeCardFromDeck = async (
    userId: string,
    deckId: string,
    scryfallId: string,
    input: RemoveDeckCardInput = {},
): Promise<RemoveDeckCardResult> => {
    const quantity = input.quantity ?? 1;
    assertPositiveQuantity(quantity);

    const result = await removeCardFromDeckForUser(
        deckId,
        userId,
        scryfallId,
        input.board ?? 'main',
        quantity,
    );

    const ownedNames = result.card?.name
        ? await getOwnedCardNamesForUser(userId, [result.card.name])
        : new Set<string>();

    return {
        removed: result.removed,
        card: result.card ? toDeckCardItem(result.card, null, ownedNames) : undefined,
    };
};
