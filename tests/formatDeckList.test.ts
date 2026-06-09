import { formatDeckList, type DeckListCardInput } from '../src/backend/scanner/formatDeckList';
import { parseDeckList } from '../src/backend/scanner/parseDeckList';

const cardsMatch = (
    left: ReturnType<typeof parseDeckList>,
    right: ReturnType<typeof parseDeckList>,
): void => {
    const normalize = (entries: ReturnType<typeof parseDeckList>) =>
        entries
            .map((e) => ({ name: e.name, quantity: e.quantity, board: e.board }))
            .sort((a, b) =>
                `${a.board}\0${a.name}`.localeCompare(`${b.board}\0${b.name}`),
            );

    expect(normalize(left)).toEqual(normalize(right));
};

describe('formatDeckList', () => {
    test('formats commander deck with commander section at end', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Sol Ring', quantity: 1, board: 'main' },
            { name: 'Plains', quantity: 12, board: 'main' },
            { name: 'Mountain', quantity: 9, board: 'main' },
            { name: 'Fireshrieker', quantity: 1, board: 'main' },
            { name: 'Wyleth, Soul of Steel', quantity: 1, board: 'commander' },
        ];

        const text = formatDeckList(cards, 'Commander');

        expect(text).toContain('12 Plains');
        expect(text).toContain('9 Mountain');
        expect(text.endsWith('// Commander\n1 Wyleth, Soul of Steel')).toBe(true);
        expect(text.indexOf('// Commander')).toBeGreaterThan(text.indexOf('Sol Ring'));
    });

    test('formats oathbreaker deck with oathbreaker section header', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Birds of Paradise', quantity: 1, board: 'main' },
            { name: 'Plains', quantity: 2, board: 'main' },
            { name: 'Jared Carthalion', quantity: 1, board: 'commander' },
        ];

        const text = formatDeckList(cards, 'Oathbreaker');

        expect(text).toContain('// Oathbreaker & Signature');
        expect(text).toContain('1 Jared Carthalion');
        expect(text).not.toContain('// Commander');
    });

    test('includes sideboard section when present', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Lightning Bolt', quantity: 1, board: 'main' },
            { name: 'Pyroblast', quantity: 2, board: 'sideboard' },
        ];

        const text = formatDeckList(cards, 'Standard');

        expect(text).toBe('1 Lightning Bolt\n\n// Sideboard\n2 Pyroblast');
    });

    test('sorts cards alphabetically within each section', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Plains', quantity: 1, board: 'main' },
            { name: 'Sol Ring', quantity: 1, board: 'main' },
            { name: 'Mountain', quantity: 1, board: 'main' },
        ];

        const text = formatDeckList(cards, 'Commander');
        const lines = text.split('\n');

        expect(lines).toEqual(['1 Mountain', '1 Plains', '1 Sol Ring']);
    });

    test('aggregates duplicate names on the same board', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Plains', quantity: 1, board: 'main' },
            { name: 'Plains', quantity: 1, board: 'main' },
            { name: 'Wear / Tear', quantity: 1, board: 'main' },
        ];

        const text = formatDeckList(cards, 'Commander');

        expect(text).toContain('2 Plains');
        expect(text).toContain('1 Wear / Tear');
    });

    test('returns empty string for empty deck', () => {
        expect(formatDeckList([], 'Commander')).toBe('');
    });

    test('round-trips commander deck through parseDeckList', () => {
        const cards: DeckListCardInput[] = [
            { name: 'Sol Ring', quantity: 1, board: 'main' },
            { name: 'Plains', quantity: 12, board: 'main' },
            { name: 'Wyleth, Soul of Steel', quantity: 1, board: 'commander' },
            { name: 'Pyroblast', quantity: 2, board: 'sideboard' },
        ];

        const text = formatDeckList(cards, 'Commander');
        const parsed = parseDeckList(text);

        cardsMatch(
            parsed,
            cards.map((c, index) => ({ ...c, line: index + 1 })),
        );
    });
});
