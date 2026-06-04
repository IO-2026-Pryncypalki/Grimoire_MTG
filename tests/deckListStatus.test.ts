import {
    computeIsFormatValid,
    computeIsFullyAssigned,
    type DeckCardStatusInput,
} from '../src/backend/services/deckListStatus';

const card = (overrides: Partial<DeckCardStatusInput>): DeckCardStatusInput => ({
    board: 'main',
    quantity: 1,
    scryfallId: 'scry-1',
    name: 'Lightning Bolt',
    typeLine: 'Instant',
    filledQty: 0,
    formatWarning: null,
    ...overrides,
});

describe('deckListStatus', () => {
    describe('computeIsFormatValid', () => {
        test('Modern deck with 60 main cards and no warnings is valid', () => {
            const cards = Array.from({ length: 60 }, (_, i) =>
                card({ scryfallId: `scry-${i}`, quantity: 1 }),
            );
            expect(computeIsFormatValid('Modern', cards)).toBe(true);
        });

        test('Modern deck with fewer than 60 main cards is invalid', () => {
            const cards = Array.from({ length: 59 }, (_, i) =>
                card({ scryfallId: `scry-${i}`, quantity: 1 }),
            );
            expect(computeIsFormatValid('Modern', cards)).toBe(false);
        });

        test('Modern deck exceeding 4 copies of same card is invalid', () => {
            const cards = [
                ...Array.from({ length: 56 }, (_, i) =>
                    card({ scryfallId: `scry-${i}`, quantity: 1 }),
                ),
                card({ scryfallId: 'dup', quantity: 5 }),
            ];
            expect(computeIsFormatValid('Modern', cards)).toBe(false);
        });

        test('Commander deck with fewer than 100 main cards is invalid', () => {
            const cards = Array.from({ length: 99 }, (_, i) =>
                card({ scryfallId: `scry-${i}`, quantity: 1 }),
            );
            expect(computeIsFormatValid('Commander', cards)).toBe(false);
        });

        test('any format warning makes deck invalid', () => {
            const cards = Array.from({ length: 60 }, (_, i) =>
                card({ scryfallId: `scry-${i}`, quantity: 1 }),
            );
            cards[0] = card({
                formatWarning: { status: 'not_legal', message: 'Banned' },
            });
            expect(computeIsFormatValid('Modern', cards)).toBe(false);
        });

        test('Custom format with no rules is valid without warnings', () => {
            expect(computeIsFormatValid('Custom', [card({ quantity: 1 })])).toBe(true);
        });
    });

    describe('computeIsFullyAssigned', () => {
        test('returns false when no cards are in collection', () => {
            const cards = [card({ name: 'Unknown', filledQty: 1 })];
            expect(computeIsFullyAssigned(cards, new Set())).toBe(false);
        });

        test('returns false when in-collection card is not fully filled', () => {
            const cards = [card({ filledQty: 2, quantity: 4 })];
            expect(computeIsFullyAssigned(cards, new Set(['lightning bolt']))).toBe(false);
        });

        test('returns true when all in-collection cards are fully assigned', () => {
            const cards = [
                card({ filledQty: 4, quantity: 4 }),
                card({ name: 'Missing', filledQty: 0, quantity: 2 }),
            ];
            expect(computeIsFullyAssigned(cards, new Set(['lightning bolt']))).toBe(true);
        });
    });
});
