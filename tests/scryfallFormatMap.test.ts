import { extractLegalitiesRows, shouldCheckFormatLegality } from '../src/backend/deck/scryfallFormatMap';

const CARD_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

const tarmogoyfLegalities = {
    standard: 'not_legal',
    future: 'not_legal',
    historic: 'not_legal',
    timeless: 'not_legal',
    gladiator: 'not_legal',
    pioneer: 'not_legal',
    modern: 'legal',
    legacy: 'legal',
    pauper: 'not_legal',
    vintage: 'legal',
    penny: 'legal',
    commander: 'legal',
    oathbreaker: 'legal',
    standardbrawl: 'not_legal',
    brawl: 'not_legal',
    alchemy: 'not_legal',
    paupercommander: 'not_legal',
    duel: 'legal',
    oldschool: 'not_legal',
    premodern: 'not_legal',
    predh: 'not_legal',
    tlr: 'legal',
};

describe('scryfallFormatMap', () => {
    test('mapuje legalności Scryfall na wiersze card_legalities', () => {
        const rows = extractLegalitiesRows(CARD_ID, tarmogoyfLegalities);

        expect(rows).toEqual(
            expect.arrayContaining([
                { scryfallId: CARD_ID, format: 'Modern', status: 'legal' },
                { scryfallId: CARD_ID, format: 'Standard', status: 'not_legal' },
                { scryfallId: CARD_ID, format: 'Commander', status: 'legal' },
            ]),
        );
        expect(rows.find((row) => row.format === 'Pioneer')).toEqual({
            scryfallId: CARD_ID,
            format: 'Pioneer',
            status: 'not_legal',
        });
    });

    test('ignoruje nieznane klucze Scryfall', () => {
        const rows = extractLegalitiesRows(CARD_ID, tarmogoyfLegalities);
        expect(rows.some((row) => (row as { format: string }).format === 'historic')).toBe(false);
    });

    test('shouldCheckFormatLegality zwraca false dla Custom', () => {
        expect(shouldCheckFormatLegality('Custom')).toBe(false);
        expect(shouldCheckFormatLegality('Modern')).toBe(true);
    });
});
