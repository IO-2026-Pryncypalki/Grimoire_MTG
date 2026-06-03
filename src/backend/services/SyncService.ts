import { fn, col } from 'sequelize';
import { CollectionEntry } from '../models/CollectionEntry';
import { Deck } from '../models/Deck';

export interface SyncStatus {
    collectionUpdatedAt: string;
    decksUpdatedAt: string;
    syncToken: string;
}

const epochIso = () => new Date(0).toISOString();

const maxTimestamp = (a: string, b: string): string => (a >= b ? a : b);

export const getSyncStatusForUser = async (userId: string): Promise<SyncStatus> => {
    const collectionResult = await CollectionEntry.findOne({
        where: { userId },
        attributes: [[fn('MAX', col('updatedAt')), 'maxUpdated']],
        raw: true,
    }) as { maxUpdated: Date | null } | null;

    const deckResult = await Deck.findOne({
        where: { userId },
        attributes: [[fn('MAX', col('updatedAt')), 'maxUpdated']],
        raw: true,
    }) as { maxUpdated: Date | null } | null;

    const collectionUpdatedAt = collectionResult?.maxUpdated
        ? new Date(collectionResult.maxUpdated).toISOString()
        : epochIso();

    const decksUpdatedAt = deckResult?.maxUpdated
        ? new Date(deckResult.maxUpdated).toISOString()
        : epochIso();

    return {
        collectionUpdatedAt,
        decksUpdatedAt,
        syncToken: maxTimestamp(collectionUpdatedAt, decksUpdatedAt),
    };
};
