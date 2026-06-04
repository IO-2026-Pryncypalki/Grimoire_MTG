import {
    buildOrQueryFromNames,
    buildScryfallSearchQuery,
    hasScryfallSearchSyntax,
} from '../src/backend/scanner/scryfallSearch';

describe('scryfallSearch helpers', () => {
    test('buildScryfallSearchQuery dodaje name: dla zwykłej nazwy', () => {
        expect(buildScryfallSearchQuery('lightning bolt')).toBe('name:lightning bolt');
    });

    test('buildScryfallSearchQuery nie zmienia składni Scryfall', () => {
        expect(hasScryfallSearchSyntax('!"Lightning Bolt"')).toBe(true);
        expect(buildScryfallSearchQuery('!"Lightning Bolt"')).toBe('!"Lightning Bolt"');
    });

    test('buildOrQueryFromNames łączy do pięciu nazw', () => {
        expect(
            buildOrQueryFromNames([
                'Lightning Bolt',
                'Lightning Helix',
                'Bolt',
            ]),
        ).toBe('!"Lightning Bolt" or !"Lightning Helix" or !"Bolt"');
    });

    test('buildOrQueryFromNames escapuje cudzysłowy w nazwie', () => {
        expect(buildOrQueryFromNames(['Alrund "God" Epiphany'])).toBe(
            '!"Alrund \\"God\\" Epiphany"',
        );
    });
});
