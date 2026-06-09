import { CardSymSpell } from '../src/backend/scanner/symspell';

describe('CardSymSpell', () => {
  let symspell: CardSymSpell;

  beforeAll(async () => {
    symspell = await CardSymSpell.fromNames([
      'Lightning Bolt',
      'Counterspell',
      'Tarmogoyf',
    ]);
  });

  test('koryguje typową literówkę OCR', () => {
    const hit = symspell.lookup('Lightnng Bolt')[0];
    expect(hit.term).toBe('lightning bolt');
    expect(hit.distance).toBeGreaterThan(0);
  });

  test('exact match ma distance 0', () => {
    const hit = symspell.lookup('Lightning Bolt')[0];
    expect(hit.term).toBe('lightning bolt');
    expect(hit.distance).toBe(0);
  });

  test('zwraca pustą listę dla pustego inputu', () => {
    expect(symspell.lookup('')).toEqual([]);
  });
});
