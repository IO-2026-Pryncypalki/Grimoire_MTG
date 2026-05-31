jest.mock('../src/backend/services/CardService', () => ({
    ensureLegalitiesInDb: jest.fn(),
}));

jest.mock('../src/backend/repositories/CardLegalityRepository', () => ({
    getLegalityStatus: jest.fn(),
    getLegalitiesForCards: jest.fn(),
}));

import { ensureLegalitiesInDb } from '../src/backend/services/CardService';
import {
    getLegalitiesForCards,
    getLegalityStatus,
} from '../src/backend/repositories/CardLegalityRepository';
import {
    getWarningForCard,
    getWarningsForDeckCards,
} from '../src/backend/services/DeckFormatWarningService';

const CARD_A = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const CARD_B = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

describe('DeckFormatWarningService', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (ensureLegalitiesInDb as jest.Mock).mockResolvedValue(undefined);
    });

    describe('getWarningForCard', () => {
        test('zwraca ostrzeżenie gdy karta not_legal w Modern', async () => {
            (getLegalityStatus as jest.Mock).mockResolvedValue('not_legal');

            const warning = await getWarningForCard(CARD_A, 'Modern');

            expect(ensureLegalitiesInDb).toHaveBeenCalledWith(CARD_A);
            expect(warning).toEqual({
                status: 'not_legal',
                message: 'Karta nie jest legalna w formacie Modern',
            });
        });

        test('zwraca null gdy karta legal', async () => {
            (getLegalityStatus as jest.Mock).mockResolvedValue('legal');

            const warning = await getWarningForCard(CARD_A, 'Modern');

            expect(warning).toBeNull();
        });

        test('zwraca null dla formatu Custom', async () => {
            (getLegalityStatus as jest.Mock).mockResolvedValue('not_legal');

            const warning = await getWarningForCard(CARD_A, 'Custom');

            expect(warning).toBeNull();
        });
    });

    describe('getWarningsForDeckCards', () => {
        test('zwraca mapę ostrzeżeń dla wielu kart', async () => {
            const statuses = new Map<string, string | null>([
                [CARD_A, 'not_legal'],
                [CARD_B, 'legal'],
            ]);
            (getLegalitiesForCards as jest.Mock).mockResolvedValue(statuses);

            const warnings = await getWarningsForDeckCards([CARD_A, CARD_B], 'Standard');

            expect(ensureLegalitiesInDb).toHaveBeenCalledTimes(2);
            expect(warnings.get(CARD_A)).toEqual({
                status: 'not_legal',
                message: 'Karta nie jest legalna w formacie Standard',
            });
            expect(warnings.get(CARD_B)).toBeNull();
        });

        test('zwraca pustą mapę dla pustej listy', async () => {
            const warnings = await getWarningsForDeckCards([], 'Modern');

            expect(warnings.size).toBe(0);
            expect(getLegalitiesForCards).not.toHaveBeenCalled();
        });
    });
});
