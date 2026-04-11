import Deck from '../src/backend/deck/Deck';
import Card from '../src/backend/collection/Card';

describe('Deck', () => {
  const makeCard = (id = 'abc-123') => new Card({
    scryfallId: id,
    name: 'Lightning Bolt',
    setCode: 'M11',
    currentPrice: 2.0,
    imageUrl: 'https://example.com/card.jpg',
  });

  const makeDeck = () => new Deck({ id: 'deck-1', name: 'Burn', format: 'Modern' });

  describe('addCard(card, count)', () => {
    test('dodaje kartę z podaną liczbą kopii', () => {
      const deck = makeDeck();
      deck.addCard(makeCard(), 4);
      expect(deck.getCard('abc-123').getQuantity()).toBe(4);
    });

    test('sumuje count przy ponownym dodaniu tej samej karty', () => {
      const deck = makeDeck();
      deck.addCard(makeCard(), 2);
      deck.addCard(makeCard(), 2);
      expect(deck.getCard('abc-123')).toBe(4);
    });

    test('rzuca błąd gdy count <= 0', () => {
      const deck = makeDeck();
      expect(() => deck.addCard(makeCard(), 0)).toThrow();
      expect(() => deck.addCard(makeCard(), -1)).toThrow();
    });
  });

  describe('removeCard(scryfallId)', () => {
    test('usuwa kartę z talii', () => {
      const deck = makeDeck();
      deck.addCard(makeCard(), 4);
      deck.removeCard('abc-123');
      expect(deck.getCard('abc-123')).toBe(false);
    });

    test('nie rzuca błędu dla nieistniejącego ID', () => {
      const deck = makeDeck();
      expect(() => deck.removeCard('nieistniejace')).not.toThrow();
    });
  });

  describe('validate(validator)', () => {
    test('wywołuje validator.isValid z deck i formatem', () => {
      const deck = makeDeck();
      const validator = { isValid: jest.fn().mockReturnValue(true) };
      deck.validate(validator);
      expect(validator.isValid).toHaveBeenCalledWith(deck, 'Modern');
    });

    test('zwraca true gdy validator zwraca true', () => {
      const deck = makeDeck();
      const validator = { isValid: jest.fn().mockReturnValue(true) };
      expect(deck.validate(validator)).toBe(true);
    });

    test('zwraca false gdy validator zwraca false', () => {
      const deck = makeDeck();
      const validator = { isValid: jest.fn().mockReturnValue(false) };
      expect(deck.validate(validator)).toBe(false);
    });
  });

  describe('searchNewCards(query, provider)', () => {
    test('wywołuje provider.searchCard z zapytaniem', async () => {
      const deck = makeDeck();
      const provider = {
        searchCard: jest.fn().mockResolvedValue([makeCard()]),
        getPrice : null,
        getCardDetails : null
      };
      await deck.searchNewCards('Lightning', provider);
      expect(provider.searchCard).toHaveBeenCalledWith('Lightning');
    });

    test('zwraca listę kart z odpowiedzi providera', async () => {
      const deck = makeDeck();
      const cards = [makeCard('a'), makeCard('b')];
      const provider = {
        searchCard: jest.fn().mockResolvedValue(cards),
        getPrice : null,
        getCardDetails : null
      };

      const result = await deck.searchNewCards('test', provider);
      expect(result).toHaveLength(2);
    });

    test('zwraca [] gdy provider zwraca pustą listę', async () => {
      const deck = makeDeck();
      const provider = { searchCard: jest.fn().mockResolvedValue([]),
        getPrice : null,
        getCardDetails : null
      };
      const result = await deck.searchNewCards('nic', provider);
      expect(result).toEqual([]);
    });
  });
});
