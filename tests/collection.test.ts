jest.mock('../src/backend/models/CollectionEntry', () => ({
    CollectionEntry: {
        findOrCreate: jest.fn().mockResolvedValue([{}, true]),
        destroy:      jest.fn().mockResolvedValue(1),
        findAll:      jest.fn().mockResolvedValue([]),
    }
}));

jest.mock('../src/backend/models/Card', () => ({
    Card: {
        update:  jest.fn().mockResolvedValue([1]),
        findAll: jest.fn().mockResolvedValue([]),
    }
}));

import Collection from '../src/backend/collection/Collection';
import Card from '../src/backend/collection/Card';

describe('Collection', () => {
  const makeCard = (id = 'abc-123' , price : number | null  = 10.0 ) => new Card({
    scryfallId: id,
    name: 'Tarmogoyf',
    setCode: 'MH2',
    currentPrice: price,
    imageUrl: 'https://example.com/card.jpg',
  });

  const makeCollection = () => new Collection({ userId: 'user-1' });

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
    test('usuwa istniejący wpis', () => {
      const col = makeCollection();
      col.addCard(makeCard());
      col.removeCard('abc-123');
      expect(col.getEntry('abc-123')).toBeNull();
    });

    test('nie rzuca błędu dla nieistniejącego scryfallId', () => {
      const col = makeCollection();
      expect(() => col.removeCard('nieistniejace-id')).not.toThrow();
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
      const provider = { searchCard : jest.fn(),
        getCardDetails : jest.fn(),
        getPrice: jest.fn().mockResolvedValue(99.0) };
      await col.refreshPrices(provider);
      expect(provider.getPrice).toHaveBeenCalledTimes(2);
    });

    test('aktualizuje currentPrice na podstawie odpowiedzi providera', async () => {
      const col = makeCollection();
      col.addCard(makeCard('a', 1.0));
      const provider = {
        getPrice: jest.fn().mockResolvedValue(42.0),
        searchCard : jest.fn(),
        getCardDetails : jest.fn(),};
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
        searchCard : jest.fn(),
        getCardDetails : jest.fn(),
      };
      await col.refreshPrices(provider);
      expect(col.getEntry('b')!.getCard().getCurrentPrice()).toBe(50.0);
    });
  });
});
