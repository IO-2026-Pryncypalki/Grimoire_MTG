import { Deck as DeckModel } from '../models/Deck';
import { DeckCard as DeckCardModel } from '../models/DeckCard';
import { DeckCardAssignment as DeckCardAssignmentModel } from '../models/DeckCardAssignment';
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';
import { Card as CardModel } from '../models/Card';
import { getFilledQuantityOnDeckCard } from './DeckCardAssignmentRepository';

export type DeckBoard = 'main' | 'sideboard' | 'commander';

export type DeckFormat =
    | 'Standard'
    | 'Pioneer'
    | 'Modern'
    | 'Legacy'
    | 'Vintage'
    | 'Commander'
    | 'Pauper'
    | 'Draft'
    | 'Sealed'
    | 'Oathbreaker'
    | 'Custom';

export interface DeckRecord {
    id: string;
    userId: string;
    name: string;
    format: DeckFormat;
    description: string | null;
    isValid: boolean | null;
    lastValidatedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}

export interface CreateDeckData {
    name: string;
    format: DeckFormat;
    description?: string | null;
}

export interface UpdateDeckData {
    name?: string;
    format?: DeckFormat;
    description?: string | null;
    isValid?: boolean | null;
    lastValidatedAt?: Date | null;
}

export interface DeckCardAssignmentRecord {
    id: string;
    collectionEntryId: string;
    quantity: number;
    condition: string;
    isFoil: boolean;
}

export interface DeckCardRecord {
    id: string;
    scryfallId: string;
    quantity: number;
    board: DeckBoard;
    name: string | null;
    setCode: string | null;
    imageUrl: string | null;
    assignments: DeckCardAssignmentRecord[];
}

export interface DeckWithCardsRecord extends DeckRecord {
    cards: DeckCardRecord[];
}

const toDeckRecord = (model: InstanceType<typeof DeckModel>): DeckRecord => {
    const raw = model.get() as Record<string, unknown>;
    return {
        id: raw.id as string,
        userId: raw.userId as string,
        name: raw.name as string,
        format: raw.format as DeckFormat,
        description: (raw.description as string | null) ?? null,
        isValid: (raw.isValid as boolean | null) ?? null,
        lastValidatedAt: (raw.lastValidatedAt as Date | null) ?? null,
        createdAt: raw.createdAt as Date,
        updatedAt: raw.updatedAt as Date,
    };
};

export const listByUser = async (userId: string): Promise<DeckRecord[]> => {
    const rows = await DeckModel.findAll({
        where: { userId },
        order: [['updatedAt', 'DESC']],
    });
    return rows.map((row) => toDeckRecord(row));
};

export const getByIdForUser = async (deckId: string, userId: string): Promise<DeckRecord | null> => {
    const row = await DeckModel.findOne({
        where: { id: deckId, userId },
    });
    return row ? toDeckRecord(row) : null;
};

const toDeckCardRecord = (deckCardRow: InstanceType<typeof DeckCardModel>): DeckCardRecord => {
    const raw = deckCardRow.get() as Record<string, unknown>;
    const cardRow = (deckCardRow as InstanceType<typeof DeckCardModel> & { Card?: InstanceType<typeof CardModel> }).Card;
    const cardRaw = cardRow?.get() as Record<string, unknown> | undefined;

    const assignmentRows = (deckCardRow as InstanceType<typeof DeckCardModel> & {
        DeckCardAssignments?: Array<
            InstanceType<typeof DeckCardAssignmentModel> & {
                CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
            }
        >;
    }).DeckCardAssignments ?? [];

    const assignments: DeckCardAssignmentRecord[] = assignmentRows.map((assignmentRow) => {
        const assignmentRaw = assignmentRow.get() as Record<string, unknown>;
        const entryRaw = assignmentRow.CollectionEntry?.get() as Record<string, unknown> | undefined;
        return {
            id: assignmentRaw.id as string,
            collectionEntryId: assignmentRaw.collectionEntryId as string,
            quantity: assignmentRaw.quantity as number,
            condition: (entryRaw?.condition as string) ?? 'NM',
            isFoil: (entryRaw?.isFoil as boolean) ?? false,
        };
    });

    return {
        id: raw.id as string,
        scryfallId: raw.scryfallId as string,
        quantity: raw.quantity as number,
        board: raw.board as DeckBoard,
        name: (cardRaw?.name as string | null) ?? null,
        setCode: (cardRaw?.setCode as string | null) ?? null,
        imageUrl: (cardRaw?.imageUri as string | null) ?? null,
        assignments,
    };
};

export const getByIdForUserWithCards = async (
    deckId: string,
    userId: string,
): Promise<DeckWithCardsRecord | null> => {
    const row = await DeckModel.findOne({
        where: { id: deckId, userId },
        include: [
            {
                model: DeckCardModel,
                include: [
                    { model: CardModel },
                    {
                        model: DeckCardAssignmentModel,
                        include: [{ model: CollectionEntryModel }],
                    },
                ],
            },
        ],
    });

    if (!row) {
        return null;
    }

    const deck = toDeckRecord(row);
    const deckCards = (row as InstanceType<typeof DeckModel> & {
        DeckCards?: InstanceType<typeof DeckCardModel>[];
    }).DeckCards ?? [];

    return {
        ...deck,
        cards: deckCards.map((deckCardRow) => toDeckCardRecord(deckCardRow)),
    };
};

export const createForUser = async (userId: string, input: CreateDeckData): Promise<DeckRecord> => {
    const row = await DeckModel.create({
        userId,
        name: input.name,
        format: input.format,
        description: input.description ?? null,
    });
    return toDeckRecord(row);
};

export const updateForUser = async (
    deckId: string,
    userId: string,
    patch: UpdateDeckData,
): Promise<DeckRecord | null> => {
    const row = await DeckModel.findOne({
        where: { id: deckId, userId },
    });

    if (!row) {
        return null;
    }

    await row.update({
        ...patch,
    });

    return toDeckRecord(row);
};

export const deleteForUser = async (deckId: string, userId: string): Promise<boolean> => {
    const deletedCount = await DeckModel.destroy({
        where: { id: deckId, userId },
    });
    return deletedCount > 0;
};

export const touchDeckUpdatedAt = async (deckId: string): Promise<void> => {
    await DeckModel.update({ updatedAt: new Date() }, { where: { id: deckId } });
    const { publishSyncForDeck } = await import('../services/syncPublish');
    await publishSyncForDeck(deckId);
};

export interface AddDeckCardData {
    scryfallId: string;
    quantity: number;
    board: DeckBoard;
}

export interface RemoveDeckCardResult {
    removed: boolean;
    card?: DeckCardRecord;
}

const findDeckCardWithCard = async (
    deckId: string,
    scryfallId: string,
    board: DeckBoard,
): Promise<InstanceType<typeof DeckCardModel> | null> =>
    DeckCardModel.findOne({
        where: { deckId, scryfallId, board },
        include: [{ model: CardModel }],
    });

export const addCardToDeckForUser = async (
    deckId: string,
    userId: string,
    input: AddDeckCardData,
): Promise<DeckCardRecord> => {
    const deck = await getByIdForUser(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }

    const card = await CardModel.findByPk(input.scryfallId);
    if (!card) {
        throw new Error('Card not found');
    }

    const existing = await findDeckCardWithCard(deckId, input.scryfallId, input.board);

    if (existing) {
        const currentQuantity = existing.get('quantity') as number;
        await existing.update({ quantity: currentQuantity + input.quantity });
        await existing.reload({ include: [{ model: CardModel }] });
        await touchDeckUpdatedAt(deckId);
        return toDeckCardRecord(existing);
    }

    const created = await DeckCardModel.create({
        deckId,
        scryfallId: input.scryfallId,
        quantity: input.quantity,
        board: input.board,
    });

    const withCard = await DeckCardModel.findByPk(created.get('id') as string, {
        include: [{ model: CardModel }],
    });

    if (!withCard) {
        throw new Error('Failed to load deck card');
    }

    await touchDeckUpdatedAt(deckId);
    return toDeckCardRecord(withCard);
};

export const removeCardFromDeckForUser = async (
    deckId: string,
    userId: string,
    scryfallId: string,
    board: DeckBoard,
    quantityToRemove: number,
): Promise<RemoveDeckCardResult> => {
    const deck = await getByIdForUser(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }

    const existing = await findDeckCardWithCard(deckId, scryfallId, board);
    if (!existing) {
        throw new Error('Deck card not found');
    }

    const currentQuantity = existing.get('quantity') as number;
    const newQuantity = currentQuantity - quantityToRemove;

    if (newQuantity <= 0) {
        await existing.destroy();
        await touchDeckUpdatedAt(deckId);
        return { removed: true };
    }

    const filled = await getFilledQuantityOnDeckCard(existing.get('id') as string);
    if (newQuantity < filled) {
        throw new Error('Cannot reduce deck card below assigned quantity');
    }

    await existing.update({ quantity: newQuantity });
    await existing.reload({ include: [{ model: CardModel }] });
    await touchDeckUpdatedAt(deckId);

    return {
        removed: false,
        card: toDeckCardRecord(existing),
    };
};
