import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';

export const touchCollectionEntryUpdatedAt = async (entryId: string): Promise<void> => {
    await CollectionEntryModel.update({ updatedAt: new Date() }, { where: { id: entryId } });
};
