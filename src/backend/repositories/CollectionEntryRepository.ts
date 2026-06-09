import { Op } from 'sequelize';
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';
import { DeckCardAssignment as DeckCardAssignmentModel } from '../models/DeckCardAssignment';

export interface DeleteCollectionEntriesFilter {
    userId: string;
    scryfallId?: string;
    condition?: string;
    isFoil?: boolean;
    entryIds?: string[];
}

export const touchCollectionEntryUpdatedAt = async (entryId: string): Promise<void> => {
    await CollectionEntryModel.update({ updatedAt: new Date() }, { where: { id: entryId } });
};

/**
 * Deletes collection entries and any deck_card_assignments referencing them.
 * Returns the number of collection_entries removed.
 */
export const deleteCollectionEntries = async (
    filter: DeleteCollectionEntriesFilter,
): Promise<number> => {
    const where: Record<string, unknown> = { userId: filter.userId };

    if (filter.entryIds?.length) {
        where.id = { [Op.in]: filter.entryIds };
    } else {
        if (!filter.scryfallId) {
            return 0;
        }
        where.scryfallId = filter.scryfallId;
        if (filter.condition !== undefined) {
            where.condition = filter.condition;
        }
        if (filter.isFoil !== undefined) {
            where.isFoil = filter.isFoil;
        }
    }

    const rows = await CollectionEntryModel.findAll({
        where,
        attributes: ['id'],
    });
    const ids = rows.map((row) => row.get('id') as string);
    if (ids.length === 0) {
        return 0;
    }

    await DeckCardAssignmentModel.destroy({
        where: { collectionEntryId: { [Op.in]: ids } },
    });

    return CollectionEntryModel.destroy({
        where: { id: { [Op.in]: ids }, userId: filter.userId },
    });
};
