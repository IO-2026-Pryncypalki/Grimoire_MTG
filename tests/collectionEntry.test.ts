jest.mock('../src/backend/models/CollectionEntry', () => ({
    CollectionEntry: {
        findOrCreate: jest.fn().mockResolvedValue([{}, true]),
        destroy:      jest.fn().mockResolvedValue(1),
        findAll:      jest.fn().mockResolvedValue([]),
        update:       jest.fn().mockResolvedValue([1]),
    }
}));

jest.mock('../src/backend/repositories/CollectionEntryRepository', () => ({
    deleteCollectionEntries: jest.fn(),
    touchCollectionEntryUpdatedAt: jest.fn(),
}));

jest.mock('../src/backend/models/Card', () => ({
    Card: {
        update:  jest.fn().mockResolvedValue([1]),
        findAll: jest.fn().mockResolvedValue([]),
    }
}));

import Collection from '../src/backend/collection/Collection';
import Card from '../src/backend/collection/Card';
import CollectionEntry from '../src/backend/collection/CollectionEntry';
import { deleteCollectionEntries } from '../src/backend/repositories/CollectionEntryRepository';
import { CollectionEntry as CollectionEntryModel } from '../src/backend/models/CollectionEntry';

describe('Collection', () => {
  const makeCard = (id = 'abc-123', price: number | null = 10.0) => new Card({
    id,
    name:       'Tarmogoyf',
    set:        'MH2',
    set_name:   'Modern Horizons 2',
    collector_number: '136',
    lang:       'en',
    mana_cost:  null,
    cmc:        null,
    type_line:  null,
    oracle_id:  null,
    prices:     price !== null ? { usd: price, usd_foil: 0, eur: 0, eur_foil: 0 } : null,
    image_uris: null,
  });

  const makeCollection = () => new Collection({ userId: 'user-1' });

  const makeEntry = (
    scryfallId = 'abc-123',
    condition = 'NM',
    quantity = 1,
    id = 'entry-1',
    isFoil = false,
  ) => new CollectionEntry({
    id,
    card: makeCard(scryfallId),
    quantity,
    condition,
    isFoil,
    notes: null,
  });

  const makeCollectionWithEntries = (entries: CollectionEntry[]) =>
    new Collection({ userId: 'user-1', entries });

  describe('transferCondition', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    test('przenosi część kopii do nowego stanu', async () => {
      (CollectionEntryModel.update as jest.Mock).mockResolvedValue([1]);
      (CollectionEntryModel.findOrCreate as jest.Mock).mockResolvedValue([
        {
          get: () => ({
            id: 'entry-lp',
            scryfallId: 'abc-123',
            quantity: 2,
            condition: 'LP',
            isFoil: false,
            notes: null,
          }),
          reload: jest.fn().mockResolvedValue(undefined),
          update: jest.fn().mockResolvedValue(undefined),
        },
        true,
      ]);

      const col = makeCollectionWithEntries([makeEntry('abc-123', 'NM', 4, 'entry-nm')]);
      await col.transferCondition('abc-123', 'NM', 'LP', false, 2);

      expect(col.getEntry('abc-123', 'NM', false)!.getQuantity()).toBe(2);
      expect(col.getEntry('abc-123', 'LP', false)!.getQuantity()).toBe(2);
    });

    test('usuwa wpis źródłowy po przeniesieniu wszystkich kopii', async () => {
      (deleteCollectionEntries as jest.Mock).mockResolvedValue(1);
      (CollectionEntryModel.findOrCreate as jest.Mock).mockResolvedValue([
        {
          get: () => ({
            id: 'entry-lp',
            scryfallId: 'abc-123',
            quantity: 1,
            condition: 'LP',
            isFoil: false,
            notes: null,
          }),
          reload: jest.fn().mockResolvedValue(undefined),
          update: jest.fn().mockResolvedValue(undefined),
        },
        true,
      ]);

      const col = makeCollectionWithEntries([makeEntry('abc-123', 'NM', 1, 'entry-nm')]);
      await col.transferCondition('abc-123', 'NM', 'LP', false, 1);

      expect(col.getEntry('abc-123', 'NM', false)).toBeNull();
      expect(col.getEntry('abc-123', 'LP', false)!.getQuantity()).toBe(1);
      expect(deleteCollectionEntries).toHaveBeenCalledWith({
        userId: 'user-1',
        entryIds: ['entry-nm'],
      });
    });

    test('inkrementuje istniejący wpis docelowy', async () => {
      (CollectionEntryModel.update as jest.Mock).mockResolvedValue([1]);

      const col = makeCollectionWithEntries([
        makeEntry('abc-123', 'NM', 2, 'entry-nm'),
        makeEntry('abc-123', 'LP', 3, 'entry-lp'),
      ]);
      await col.transferCondition('abc-123', 'NM', 'LP', false, 1);

      expect(col.getEntry('abc-123', 'NM', false)!.getQuantity()).toBe(1);
      expect(col.getEntry('abc-123', 'LP', false)!.getQuantity()).toBe(4);
    });

    test('rzuca błąd gdy brakuje kopii w stanie źródłowym', async () => {
      const col = makeCollectionWithEntries([makeEntry('abc-123', 'NM', 1, 'entry-nm')]);
      await expect(
        col.transferCondition('abc-123', 'NM', 'LP', false, 2),
      ).rejects.toThrow('Not enough cards in that condition');
    });
  });

  describe('addCard(card)', () => {
    test('tworzy nowy wpis z quantity=1 gdy karty nie ma w kolekcji', () => {
      const col = makeCollection();
      col.addCard(makeCard());
      const entry = col.getEntry('abc-123')!;
      expect(entry).not.toBeNull();
      expect(entry.getQuantity()).toBe(1);
    });

    test('inkrementuje quantity gdy karta już istnieje', () => {
      const col = makeCollection();
      col.addCard(makeCard());
      col.addCard(makeCard());
      expect(col.getEntry('abc-123')!.getQuantity()).toBe(2);
    });

    test('rzuca błąd gdy card jest null', () => {
      const col = makeCollection();
      expect(() => col.addCard(null)).toThrow();
    });
  });

  describe('removeCard(scryfallId)', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    test('usuwa istniejący wpis po potwierdzeniu w bazie', async () => {
      (deleteCollectionEntries as jest.Mock).mockResolvedValue(1);
      const col = makeCollection();
      col.addCard(makeCard());
      const removed = await col.removeCard('abc-123');
      expect(removed).toBe(1);
      expect(col.getEntry('abc-123')).toBeNull();
    });

    test('zostawia wpisy gdy baza nic nie usunęła', async () => {
      (deleteCollectionEntries as jest.Mock).mockResolvedValue(0);
      const col = makeCollection();
      col.addCard(makeCard());
      const removed = await col.removeCard('nieistniejace-id');
      expect(removed).toBe(0);
      expect(col.getEntry('abc-123')).not.toBeNull();
    });
  });

  describe('getEntry(scryfallId)', () => {
    test('zwraca CollectionEntry dla istniejącej karty', () => {
      const col = makeCollection();
      col.addCard(makeCard());
      expect(col.getEntry('abc-123')).not.toBeNull();
    });

    test('zwraca null dla nieobecnej karty', () => {
      const col = makeCollection();
      expect(col.getEntry('nieistniejace-id')).toBeNull();
    });
  });

  describe('calculateTotalValue()', () => {
    test('zwraca sumę cen * quantity', () => {
      const col = makeCollection();
      col.addCard(makeCard('a', 10.0));
      col.addCard(makeCard('a', 10.0));
      col.addCard(makeCard('b', 5.0));
      expect(col.calculateTotalValue()).toBeCloseTo(25.0);
    });

    test('zwraca 0 dla pustej kolekcji', () => {
      const col = makeCollection();
      expect(col.calculateTotalValue()).toBe(0);
    });

    test('traktuje currentPrice=null jako 0', () => {
      const col = makeCollection();
      col.addCard(makeCard('a', null));
      expect(col.calculateTotalValue()).toBe(0);
    });
  });

  describe('refreshPrices(provider)', () => {
    test('wywołuje provider.getPrice dla każdej karty', async () => {
      const col = makeCollection();
      col.addCard(makeCard('a', 10.0));
      col.addCard(makeCard('b', 5.0));
      const provider = {
        searchCard:     jest.fn(),
        getCardDetails: jest.fn(),
        getPrice:       jest.fn().mockResolvedValue(99.0),
      };
      await col.refreshPrices(provider);
      expect(provider.getPrice).toHaveBeenCalledTimes(2);
    });

    test('aktualizuje currentPrice na podstawie odpowiedzi providera', async () => {
      const col = makeCollection();
      col.addCard(makeCard('a', 1.0));
      const provider = {
        getPrice:       jest.fn().mockResolvedValue(42.0),
        searchCard:     jest.fn(),
        getCardDetails: jest.fn(),
      };
      await col.refreshPrices(provider);
      expect(col.getEntry('a')!.getCard().getCurrentPrice()).toBe(42.0);
    });

    test('kontynuuje aktualizację pozostałych kart gdy jedna rzuca błąd', async () => {
      const col = makeCollection();
      col.addCard(makeCard('a', 1.0));
      col.addCard(makeCard('b', 1.0));
      const provider = {
        getPrice: jest.fn()
          .mockRejectedValueOnce(new Error('API error'))
          .mockResolvedValueOnce(50.0),
        searchCard:     jest.fn(),
        getCardDetails: jest.fn(),
      };
      await col.refreshPrices(provider);
      expect(col.getEntry('b')!.getCard().getCurrentPrice()).toBe(50.0);
    });
  });
});