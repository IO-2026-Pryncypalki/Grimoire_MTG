import FormatValidator from '../src/backend/deck/FormatValidator';
import Deck from'../src/backend/deck/Deck';
import Card from '../src/backend/collection/Card';

describe('FormatValidator', () => {
  let validator;

  beforeEach(() => {
    validator = new FormatValidator();
  });

  const makeCard = (id, isBasicLand = false) => new Card({
    scryfallId: id,
    name: isBasicLand ? 'Forest' : `Card-${id}`,
    setCode: 'M21',
    currentPrice: 1.0,
    imageUrl: '',

  });

  const buildDeck = (format, cardCounts) => {
    const deck = new Deck({ id: 'd', name: 'Test', format });
    for (const [id, count, isBasicLand] of cardCounts) {
      deck.addCard(makeCard(id, isBasicLand), count);
    }
    return deck;
  };

  describe('Standard', () => {
    test('akceptuje deck z 60 kartami i max 4 kopiami', () => {
      const cards = Array.from({ length: 15 }, (_, i) => [`card-${i}`, 4, false]);
      const deck = buildDeck('Standard', cards);
      expect(validator.isValid(deck, 'Standard')).toBe(true);
    });

    test('odrzuca deck z < 60 kartami', () => {
      const cards = Array.from({ length: 10 }, (_, i) => [`card-${i}`, 4, false]);
      const deck = buildDeck('Standard', cards); // 40 kart
      expect(validator.isValid(deck, 'Standard')).toBe(false);
    });

    test('odrzuca deck z > 4 kopiami tej samej karty (nie-basic)', () => {
      const cards = [['broken-card', 5, false], ...Array.from({ length: 11 }, (_, i) => [`c${i}`, 5, false])];
      const deck = buildDeck('Standard', cards);
      expect(validator.isValid(deck, 'Standard')).toBe(false);
    });
  });

  describe('Commander', () => {
    test('akceptuje deck z dokładnie 100 kartami i max 1 kopią (poza basic land)', () => {
      const nonBasic = Array.from({ length: 60 }, (_, i) => [`nb-${i}`, 1, false]);
      const basic = Array.from({ length: 40 }, (_, i) => [`forest-${i}`, 1, true]);
      const deck = buildDeck('Commander', [...nonBasic, ...basic]);
      expect(validator.isValid(deck, 'Commander')).toBe(true);
    });

    test('odrzuca deck z ≠ 100 kartami', () => {
      const cards = Array.from({ length: 99 }, (_, i) => [`c-${i}`, 1, false]);
      const deck = buildDeck('Commander', cards);
      expect(validator.isValid(deck, 'Commander')).toBe(false);
    });

    test('odrzuca deck z > 1 kopią karty niebędącej basic landem', () => {
      const cards = [['broken', 2, false], ...Array.from({ length: 98 }, (_, i) => [`c${i}`, 1, false])];
      const deck = buildDeck('Commander', cards);
      expect(validator.isValid(deck, 'Commander')).toBe(false);
    });
  });

  describe('Wspólne', () => {
    test('rzuca błąd dla nieznanego formatu', () => {
      const deck = buildDeck('Nieznany', [['c1', 60, false]]);
      expect(() => validator.isValid(deck, 'Nieznany')).toThrow();
    });

    test('rzuca błąd gdy deck jest null', () => {
      expect(() => validator.isValid(null, 'Standard')).toThrow();
    });
  });
});
