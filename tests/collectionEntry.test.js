const CollectionEntry = require('../src/collection/CollectionEntry');
const Card = require('../src/collection/Card');

describe('CollectionEntry', () => {
  const makeCard = () => new Card({
    scryfallId: 'abc-123',
    name: 'Tarmogoyf',
    setCode: 'MH2',
    currentPrice: 10.0,
    imageUrl: 'https://example.com/card.jpg',
  });

  const makeEntry = () => new CollectionEntry({
    card: makeCard(),
    quantity: 2,
    condition: 'NM',
    notes: '',
  });

  describe('updateQuantity(delta)', () => {
    test('zwiększa quantity o dodatnią deltę', () => {
      const entry = makeEntry();
      entry.updateQuantity(3);
      expect(entry.quantity).toBe(5);
    });

    test('zmniejsza quantity o ujemną deltę', () => {
      const entry = makeEntry();
      entry.updateQuantity(-1);
      expect(entry.quantity).toBe(1);
    });

    test('delta 0 nie zmienia quantity', () => {
      const entry = makeEntry();
      entry.updateQuantity(0);
      expect(entry.quantity).toBe(2);
    });

    test('rzuca błąd gdy wynikowa quantity byłaby ujemna', () => {
      const entry = makeEntry();
      expect(() => entry.updateQuantity(-10)).toThrow();
    });
  });

  describe('setCondition(condition)', () => {
    test('akceptuje NM', () => {
      const entry = makeEntry();
      entry.setCondition('NM');
      expect(entry.condition).toBe('NM');
    });

    test('akceptuje GD', () => {
      const entry = makeEntry();
      entry.setCondition('GD');
      expect(entry.condition).toBe('GD');
    });

    test('akceptuje LP', () => {
      const entry = makeEntry();
      entry.setCondition('LP');
      expect(entry.condition).toBe('LP');
    });

    test('rzuca błąd dla niepoprawnej wartości', () => {
      const entry = makeEntry();
      expect(() => entry.setCondition('XYZ')).toThrow();
    });

    test('rzuca błąd dla pustego stringa', () => {
      const entry = makeEntry();
      expect(() => entry.setCondition('')).toThrow();
    });
  });

  describe('setNotes(notes)', () => {
    test('ustawia dowolny tekst', () => {
      const entry = makeEntry();
      entry.setNotes('foil, lekkie zagięcie');
      expect(entry.notes).toBe('foil, lekkie zagięcie');
    });

    test('akceptuje pusty string', () => {
      const entry = makeEntry();
      entry.setNotes('');
      expect(entry.notes).toBe('');
    });

    test('akceptuje null (czyszczenie notatki)', () => {
      const entry = makeEntry();
      entry.setNotes(null);
      expect(entry.notes).toBeNull();
    });
  });
});
