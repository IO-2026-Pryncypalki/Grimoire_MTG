jest.mock('../src/backend/models/CollectionEntry', () => ({
    CollectionEntry: {
        findAll: jest.fn(),
        destroy: jest.fn(),
    },
}));

jest.mock('../src/backend/models/DeckCardAssignment', () => ({
    DeckCardAssignment: {
        destroy: jest.fn(),
    },
}));

import { Op } from 'sequelize';
import { CollectionEntry as CollectionEntryModel } from '../src/backend/models/CollectionEntry';
import { DeckCardAssignment as DeckCardAssignmentModel } from '../src/backend/models/DeckCardAssignment';
import { deleteCollectionEntries } from '../src/backend/repositories/CollectionEntryRepository';

describe('deleteCollectionEntries', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('returns 0 when no matching entries', async () => {
        (CollectionEntryModel.findAll as jest.Mock).mockResolvedValue([]);

        const removed = await deleteCollectionEntries({
            userId: 'user-1',
            scryfallId: 'abc-123',
            condition: 'NM',
            isFoil: false,
        });

        expect(removed).toBe(0);
        expect(DeckCardAssignmentModel.destroy).not.toHaveBeenCalled();
        expect(CollectionEntryModel.destroy).not.toHaveBeenCalled();
    });

    test('removes deck assignments before collection entries', async () => {
        const order: string[] = [];
        (CollectionEntryModel.findAll as jest.Mock).mockResolvedValue([
            { get: (key: string) => (key === 'id' ? 'entry-1' : undefined) },
        ]);
        (DeckCardAssignmentModel.destroy as jest.Mock).mockImplementation(async () => {
            order.push('assignments');
            return 1;
        });
        (CollectionEntryModel.destroy as jest.Mock).mockImplementation(async () => {
            order.push('entries');
            return 1;
        });

        const removed = await deleteCollectionEntries({
            userId: 'user-1',
            entryIds: ['entry-1'],
        });

        expect(removed).toBe(1);
        expect(order).toEqual(['assignments', 'entries']);
        expect(DeckCardAssignmentModel.destroy).toHaveBeenCalledWith({
            where: { collectionEntryId: { [Op.in]: ['entry-1'] } },
        });
    });
});
