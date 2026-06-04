import { cardNamesMatch, normalizeCardName } from '../src/backend/utils/cardNameMatch';

describe('cardNameMatch', () => {
    test('normalizeCardName trims and lowercases', () => {
        expect(normalizeCardName('  Lightning Bolt  ')).toBe('lightning bolt');
    });

    test('cardNamesMatch is case-insensitive', () => {
        expect(cardNamesMatch('Lightning Bolt', 'lightning bolt')).toBe(true);
        expect(cardNamesMatch('Lightning Bolt', 'Counterspell')).toBe(false);
        expect(cardNamesMatch(null, 'Bolt')).toBe(false);
    });
});
