import { Op, QueryTypes } from 'sequelize';
import sequelize from '../config/database';
import { Deck as DeckModel } from '../models/Deck';
import { DeckCard as DeckCardModel } from '../models/DeckCard';
import { DeckCardAssignment as DeckCardAssignmentModel } from '../models/DeckCardAssignment';
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';
import { Card as CardModel } from '../models/Card';
import type { CardCondition } from '../models/CollectionEntry';
import { normalizeCardName } from '../utils/cardNameMatch';

export interface AssignmentRecord {
    id: string;
    deckCardId: string;
    collectionEntryId: string;
    quantity: number;
    condition: CardCondition;
    isFoil: boolean;
}

export interface DeckCardWithDeckRecord {
    id: string;
    deckId: string;
    scryfallId: string;
    name: string | null;
    quantity: number;
    board: string;
}

export interface CollectionEntryByNameRecord {
    id: string;
    scryfallId: string;
    name: string | null;
    setCode: string | null;
    quantity: number;
    condition: CardCondition;
    isFoil: boolean;
}

export const getAssignedTotalsByCollectionEntry = async (
    userId: string,
): Promise<Map<string, number>> => {
    const rows = await DeckCardAssignmentModel.findAll({
        attributes: ['collectionEntryId', 'quantity'],
        include: [
            {
                model: DeckCardModel,
                required: true,
                attributes: [],
                include: [
                    {
                        model: DeckModel,
                        required: true,
                        attributes: [],
                        where: { userId },
                    },
                ],
            },
        ],
    });

    const totals = new Map<string, number>();
    for (const row of rows) {
        const raw = row.get() as { collectionEntryId: string; quantity: number };
        const current = totals.get(raw.collectionEntryId) ?? 0;
        totals.set(raw.collectionEntryId, current + raw.quantity);
    }
    return totals;
};

export const findDeckCardForUser = async (
    deckCardId: string,
    deckId: string,
    userId: string,
): Promise<DeckCardWithDeckRecord | null> => {
    const row = await DeckCardModel.findOne({
        where: { id: deckCardId, deckId },
        include: [
            {
                model: DeckModel,
                required: true,
                where: { userId },
            },
            { model: CardModel, required: false },
        ],
    });

    if (!row) {
        return null;
    }

    const raw = row.get() as Record<string, unknown>;
    const cardRow = (row as InstanceType<typeof DeckCardModel> & {
        Card?: InstanceType<typeof CardModel>;
    }).Card;
    const cardRaw = cardRow?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        deckId: raw.deckId as string,
        scryfallId: raw.scryfallId as string,
        name: (cardRaw?.name as string | null) ?? null,
        quantity: raw.quantity as number,
        board: raw.board as string,
    };
};

export const getAssignmentsForDeckCard = async (deckCardId: string): Promise<AssignmentRecord[]> => {
    const rows = await DeckCardAssignmentModel.findAll({
        where: { deckCardId },
        include: [{ model: CollectionEntryModel, required: true }],
    });

    return rows.map((row) => {
        const raw = row.get() as Record<string, unknown>;
        const entry = (row as InstanceType<typeof DeckCardAssignmentModel> & {
            CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
        }).CollectionEntry;
        const entryRaw = entry?.get() as Record<string, unknown> | undefined;

        return {
            id: raw.id as string,
            deckCardId: raw.deckCardId as string,
            collectionEntryId: raw.collectionEntryId as string,
            quantity: raw.quantity as number,
            condition: entryRaw?.condition as CardCondition,
            isFoil: entryRaw?.isFoil as boolean,
        };
    });
};

export const getAssignmentForUser = async (
    assignmentId: string,
    deckCardId: string,
    deckId: string,
    userId: string,
): Promise<AssignmentRecord | null> => {
    const row = await DeckCardAssignmentModel.findOne({
        where: { id: assignmentId, deckCardId },
        include: [
            {
                model: DeckCardModel,
                required: true,
                where: { deckId },
                include: [
                    {
                        model: DeckModel,
                        required: true,
                        where: { userId },
                    },
                ],
            },
            { model: CollectionEntryModel, required: true },
        ],
    });

    if (!row) {
        return null;
    }

    const raw = row.get() as Record<string, unknown>;
    const entry = (row as InstanceType<typeof DeckCardAssignmentModel> & {
        CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
    }).CollectionEntry;
    const entryRaw = entry?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        deckCardId: raw.deckCardId as string,
        collectionEntryId: raw.collectionEntryId as string,
        quantity: raw.quantity as number,
        condition: entryRaw?.condition as CardCondition,
        isFoil: entryRaw?.isFoil as boolean,
    };
};

export const findCollectionEntryForUser = async (
    collectionEntryId: string,
    userId: string,
): Promise<{
    id: string;
    scryfallId: string;
    name: string | null;
    quantity: number;
    condition: CardCondition;
    isFoil: boolean;
} | null> => {
    const row = await CollectionEntryModel.findOne({
        where: { id: collectionEntryId, userId },
        include: [{ model: CardModel, required: false }],
    });

    if (!row) {
        return null;
    }

    const raw = row.get() as Record<string, unknown>;
    const cardRow = (row as InstanceType<typeof CollectionEntryModel> & {
        Card?: InstanceType<typeof CardModel>;
    }).Card;
    const cardRaw = cardRow?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        scryfallId: raw.scryfallId as string,
        name: (cardRaw?.name as string | null) ?? null,
        quantity: raw.quantity as number,
        condition: raw.condition as CardCondition,
        isFoil: raw.isFoil as boolean,
    };
};

export const listCollectionEntriesForScryfall = async (
    userId: string,
    scryfallId: string,
): Promise<Array<{ id: string; quantity: number; condition: CardCondition; isFoil: boolean }>> => {
    const rows = await CollectionEntryModel.findAll({
        where: { userId, scryfallId },
        order: [['condition', 'ASC'], ['isFoil', 'ASC']],
    });

    return rows.map((row) => {
        const raw = row.get() as Record<string, unknown>;
        return {
            id: raw.id as string,
            quantity: raw.quantity as number,
            condition: raw.condition as CardCondition,
            isFoil: raw.isFoil as boolean,
        };
    });
};

export const listCollectionEntriesForCardName = async (
    userId: string,
    cardName: string,
): Promise<CollectionEntryByNameRecord[]> => {
    const normalized = normalizeCardName(cardName);
    if (!normalized) {
        return [];
    }

    const rows = await CollectionEntryModel.findAll({
        where: { userId },
        include: [
            {
                model: CardModel,
                required: true,
                where: sequelize.where(
                    sequelize.fn('lower', sequelize.fn('trim', sequelize.col('Card.name'))),
                    normalized,
                ),
            },
        ],
        order: [
            [{ model: CardModel, as: 'Card' }, 'set_code', 'ASC'],
            ['condition', 'ASC'],
            ['isFoil', 'ASC'],
        ],
    });

    return rows.map((row) => {
        const raw = row.get() as Record<string, unknown>;
        const cardRow = (row as InstanceType<typeof CollectionEntryModel> & {
            Card?: InstanceType<typeof CardModel>;
        }).Card;
        const cardRaw = cardRow?.get() as Record<string, unknown> | undefined;

        return {
            id: raw.id as string,
            scryfallId: raw.scryfallId as string,
            name: (cardRaw?.name as string | null) ?? null,
            setCode: (cardRaw?.setCode as string | null) ?? null,
            quantity: raw.quantity as number,
            condition: raw.condition as CardCondition,
            isFoil: raw.isFoil as boolean,
        };
    });
};

export const createAssignment = async (
    deckCardId: string,
    collectionEntryId: string,
    quantity: number,
): Promise<AssignmentRecord> => {
    const row = await DeckCardAssignmentModel.create({
        deckCardId,
        collectionEntryId,
        quantity,
    });

    const withEntry = await DeckCardAssignmentModel.findByPk(row.get('id') as string, {
        include: [{ model: CollectionEntryModel, required: true }],
    });

    if (!withEntry) {
        throw new Error('Failed to load assignment');
    }

    const raw = withEntry.get() as Record<string, unknown>;
    const entry = (withEntry as InstanceType<typeof DeckCardAssignmentModel> & {
        CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
    }).CollectionEntry;
    const entryRaw = entry?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        deckCardId: raw.deckCardId as string,
        collectionEntryId: raw.collectionEntryId as string,
        quantity: raw.quantity as number,
        condition: entryRaw?.condition as CardCondition,
        isFoil: entryRaw?.isFoil as boolean,
    };
};

export const updateAssignmentQuantity = async (
    assignmentId: string,
    quantity: number,
): Promise<AssignmentRecord> => {
    const row = await DeckCardAssignmentModel.findByPk(assignmentId, {
        include: [{ model: CollectionEntryModel, required: true }],
    });

    if (!row) {
        throw new Error('Assignment not found');
    }

    await row.update({ quantity });
    await row.reload({ include: [{ model: CollectionEntryModel, required: true }] });

    const raw = row.get() as Record<string, unknown>;
    const entry = (row as InstanceType<typeof DeckCardAssignmentModel> & {
        CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
    }).CollectionEntry;
    const entryRaw = entry?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        deckCardId: raw.deckCardId as string,
        collectionEntryId: raw.collectionEntryId as string,
        quantity: raw.quantity as number,
        condition: entryRaw?.condition as CardCondition,
        isFoil: entryRaw?.isFoil as boolean,
    };
};

export const deleteAssignment = async (assignmentId: string): Promise<boolean> => {
    const deleted = await DeckCardAssignmentModel.destroy({
        where: { id: assignmentId },
    });
    return deleted > 0;
};

export const findAssignmentOnDeckCard = async (
    deckCardId: string,
    collectionEntryId: string,
): Promise<AssignmentRecord | null> => {
    const row = await DeckCardAssignmentModel.findOne({
        where: { deckCardId, collectionEntryId },
        include: [{ model: CollectionEntryModel, required: true }],
    });

    if (!row) {
        return null;
    }

    const raw = row.get() as Record<string, unknown>;
    const entry = (row as InstanceType<typeof DeckCardAssignmentModel> & {
        CollectionEntry?: InstanceType<typeof CollectionEntryModel>;
    }).CollectionEntry;
    const entryRaw = entry?.get() as Record<string, unknown> | undefined;

    return {
        id: raw.id as string,
        deckCardId: raw.deckCardId as string,
        collectionEntryId: raw.collectionEntryId as string,
        quantity: raw.quantity as number,
        condition: entryRaw?.condition as CardCondition,
        isFoil: entryRaw?.isFoil as boolean,
    };
};

export const getFilledQuantityOnDeckCard = async (deckCardId: string): Promise<number> => {
    const assignments = await getAssignmentsForDeckCard(deckCardId);
    return assignments.reduce((sum, a) => sum + a.quantity, 0);
};

export interface CollectionEntryAssignmentLocation {
    id: string;
    deckCardId: string;
    deckId: string;
    deckName: string;
    quantity: number;
}

export const listAssignmentsForCollectionEntry = async (
    userId: string,
    collectionEntryId: string,
    excludeDeckCardId?: string,
): Promise<CollectionEntryAssignmentLocation[]> => {
    const rows = await DeckCardAssignmentModel.findAll({
        where: { collectionEntryId },
        include: [
            {
                model: DeckCardModel,
                required: true,
                where: excludeDeckCardId ? { id: { [Op.ne]: excludeDeckCardId } } : undefined,
                include: [
                    {
                        model: DeckModel,
                        required: true,
                        where: { userId },
                    },
                ],
            },
        ],
        order: [['id', 'ASC']],
    });

    return rows.map((row) => {
        const raw = row.get() as Record<string, unknown>;
        const deckCard = (row as InstanceType<typeof DeckCardAssignmentModel> & {
            DeckCard?: InstanceType<typeof DeckCardModel> & { Deck?: InstanceType<typeof DeckModel> };
        }).DeckCard;
        const deckCardRaw = deckCard?.get() as Record<string, unknown> | undefined;
        const deck = deckCard?.Deck;
        const deckRaw = deck?.get() as Record<string, unknown> | undefined;

        return {
            id: raw.id as string,
            deckCardId: raw.deckCardId as string,
            deckId: deckCardRaw?.deckId as string,
            deckName: (deckRaw?.name as string) ?? '',
            quantity: raw.quantity as number,
        };
    });
};

export interface ReclaimCollectionEntryResult {
    reclaimed: number;
    affectedDeckIds: string[];
}

export const reclaimCollectionEntryQuantity = async (
    userId: string,
    collectionEntryId: string,
    amount: number,
    excludeDeckCardId: string,
    preferDeckId?: string,
): Promise<ReclaimCollectionEntryResult> => {
    if (amount <= 0) {
        return { reclaimed: 0, affectedDeckIds: [] };
    }

    const elsewhere = await listAssignmentsForCollectionEntry(
        userId,
        collectionEntryId,
        excludeDeckCardId,
    );

    const ordered = preferDeckId
        ? [
              ...elsewhere.filter((a) => a.deckId === preferDeckId),
              ...elsewhere.filter((a) => a.deckId !== preferDeckId),
          ]
        : elsewhere;

    let remaining = amount;
    let reclaimed = 0;
    const affectedDeckIds = new Set<string>();

    for (const assignment of ordered) {
        if (remaining <= 0) {
            break;
        }

        affectedDeckIds.add(assignment.deckId);

        if (assignment.quantity <= remaining) {
            await deleteAssignment(assignment.id);
            reclaimed += assignment.quantity;
            remaining -= assignment.quantity;
        } else {
            await updateAssignmentQuantity(assignment.id, assignment.quantity - remaining);
            reclaimed += remaining;
            remaining = 0;
        }
    }

    return {
        reclaimed,
        affectedDeckIds: [...affectedDeckIds],
    };
};

export interface DeckQuantityByNameOptions {
    excludeDeckCardId?: string;
}

export interface DeckUsingCardRecord {
    deckId: string;
    deckName: string;
    deckCardId: string;
    quantity: number;
}

export const getOwnedQuantityByCardName = async (
    userId: string,
    cardName: string,
): Promise<number> => {
    const normalized = normalizeCardName(cardName);
    if (!normalized) {
        return 0;
    }

    const rows = await sequelize.query<{ total: number }>(
        `
        SELECT COALESCE(SUM(ce.quantity), 0)::int AS total
        FROM collection_entries ce
        INNER JOIN cards c ON c.scryfall_id = ce.scryfall_id
        WHERE ce.user_id = :userId
          AND lower(trim(c.name)) = :normalized
        `,
        {
            replacements: { userId, normalized },
            type: QueryTypes.SELECT,
        },
    );

    return rows[0]?.total ?? 0;
};

export const getDeckQuantityByCardName = async (
    userId: string,
    cardName: string,
    opts: DeckQuantityByNameOptions = {},
): Promise<number> => {
    const normalized = normalizeCardName(cardName);
    if (!normalized) {
        return 0;
    }

    const excludeClause = opts.excludeDeckCardId
        ? 'AND dc.id <> :excludeDeckCardId'
        : '';

    const rows = await sequelize.query<{ total: number }>(
        `
        SELECT COALESCE(SUM(dc.quantity), 0)::int AS total
        FROM deck_cards dc
        INNER JOIN decks d ON d.id = dc.deck_id
        INNER JOIN cards c ON c.scryfall_id = dc.scryfall_id
        WHERE d.user_id = :userId
          AND lower(trim(c.name)) = :normalized
          ${excludeClause}
        `,
        {
            replacements: {
                userId,
                normalized,
                ...(opts.excludeDeckCardId ? { excludeDeckCardId: opts.excludeDeckCardId } : {}),
            },
            type: QueryTypes.SELECT,
        },
    );

    return rows[0]?.total ?? 0;
};

export const listDecksUsingCardName = async (
    userId: string,
    cardName: string,
): Promise<DeckUsingCardRecord[]> => {
    const normalized = normalizeCardName(cardName);
    if (!normalized) {
        return [];
    }

    const rows = await sequelize.query<{
        deck_id: string;
        deck_name: string;
        deck_card_id: string;
        quantity: number;
    }>(
        `
        SELECT
            d.id AS deck_id,
            d.name AS deck_name,
            dc.id AS deck_card_id,
            dc.quantity
        FROM deck_cards dc
        INNER JOIN decks d ON d.id = dc.deck_id
        INNER JOIN cards c ON c.scryfall_id = dc.scryfall_id
        WHERE d.user_id = :userId
          AND lower(trim(c.name)) = :normalized
        ORDER BY d.name ASC, dc.id ASC
        `,
        {
            replacements: { userId, normalized },
            type: QueryTypes.SELECT,
        },
    );

    return rows.map((row) => ({
        deckId: row.deck_id,
        deckName: row.deck_name,
        deckCardId: row.deck_card_id,
        quantity: row.quantity,
    }));
};

export const getOwnedCardNamesForUser = async (
    userId: string,
    cardNames: string[],
): Promise<Set<string>> => {
    const normalized = [
        ...new Set(
            cardNames.map((name) => normalizeCardName(name)).filter((n) => n.length > 0),
        ),
    ];

    if (normalized.length === 0) {
        return new Set();
    }

    const rows = await sequelize.query<{ name: string }>(
        `
        SELECT DISTINCT lower(trim(c.name)) AS name
        FROM collection_entries ce
        INNER JOIN cards c ON c.scryfall_id = ce.scryfall_id
        WHERE ce.user_id = :userId
          AND lower(trim(c.name)) IN (:names)
        `,
        {
            replacements: { userId, names: normalized },
            type: QueryTypes.SELECT,
        },
    );

    return new Set(rows.map((row) => row.name));
};
