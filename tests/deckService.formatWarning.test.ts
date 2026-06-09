jest.mock('../src/backend/repositories/DeckCardAssignmentRepository', () => ({
    getOwnedCardNamesForUser: jest.fn(),
}));

jest.mock('../src/backend/repositories/DeckRepository', () => ({
    addCardToDeckForUser: jest.fn(),
    getByIdForUser: jest.fn(),
    getByIdForUserWithCards: jest.fn(),
}));

jest.mock('../src/backend/services/DeckCardAssignmentService', () => ({
    assignCollectionEntry: jest.fn(),
    buildDeckCardFillStatus: jest.fn(() => ({
        quantity: 1,
        filledQty: 0,
        unfilledQty: 1,
        assignments: [],
    })),
}));

jest.mock('../src/backend/services/DeckFormatWarningService', () => ({
    getWarningForCard: jest.fn(),
    getWarningsForDeckCards: jest.fn(),
}));

jest.mock('../src/backend/services/CardService', () => ({
    ensureCardInDb: jest.fn(),
}));

import {
    addCardToDeckForUser,
    getByIdForUser,
    getByIdForUserWithCards,
} from '../src/backend/repositories/DeckRepository';
import { getOwnedCardNamesForUser } from '../src/backend/repositories/DeckCardAssignmentRepository';
import { ensureCardInDb } from '../src/backend/services/CardService';
import {
    getWarningForCard,
    getWarningsForDeckCards,
} from '../src/backend/services/DeckFormatWarningService';
import { addCardToDeck, getDeckDetails } from '../src/backend/services/DeckService';

const USER_ID = 'user-1';
const DECK_ID = 'deck-1';
const CARD_ID = 'card-1';
const SCRYFALL_ID = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

const deckMeta = {
    id: DECK_ID,
    userId: USER_ID,
    name: 'Modern Burn',
    format: 'Modern' as const,
    description: null,
    isValid: null,
    lastValidatedAt: null,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
};

const deckCardRecord = {
    id: CARD_ID,
    scryfallId: SCRYFALL_ID,
    quantity: 1,
    board: 'main' as const,
    name: 'Lightning Bolt',
    setCode: 'tsr',
    imageUrl: 'https://example.com/bolt.jpg',
    assignments: [],
};

describe('DeckService formatWarning', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        (ensureCardInDb as jest.Mock).mockResolvedValue({
            get: (field: string) => (field === 'name' ? 'Lightning Bolt' : SCRYFALL_ID),
        });
        (getOwnedCardNamesForUser as jest.Mock).mockResolvedValue(new Set(['lightning bolt']));
    });

    describe('addCardToDeck', () => {
        test('zwraca formatWarning gdy karta nielegalna w formacie decku', async () => {
            (getByIdForUser as jest.Mock).mockResolvedValue(deckMeta);
            (addCardToDeckForUser as jest.Mock).mockResolvedValue(deckCardRecord);
            (getByIdForUserWithCards as jest.Mock).mockResolvedValue({
                ...deckMeta,
                cards: [deckCardRecord],
            });
            (getWarningForCard as jest.Mock).mockResolvedValue({
                status: 'not_legal',
                message: 'Karta nie jest legalna w formacie Modern',
            });

            const result = await addCardToDeck(USER_ID, DECK_ID, { scryfallId: SCRYFALL_ID });

            expect(ensureCardInDb).toHaveBeenCalledWith(SCRYFALL_ID);
            expect(addCardToDeckForUser).toHaveBeenCalled();
            expect(getWarningForCard).toHaveBeenCalledWith(SCRYFALL_ID, 'Modern');
            expect(result.formatWarning).toEqual({
                status: 'not_legal',
                message: 'Karta nie jest legalna w formacie Modern',
            });
            expect(result.card.formatWarning).toEqual(result.formatWarning);
        });

        test('zwraca null formatWarning gdy karta legalna', async () => {
            (getByIdForUser as jest.Mock).mockResolvedValue(deckMeta);
            (addCardToDeckForUser as jest.Mock).mockResolvedValue(deckCardRecord);
            (getByIdForUserWithCards as jest.Mock).mockResolvedValue({
                ...deckMeta,
                cards: [deckCardRecord],
            });
            (getWarningForCard as jest.Mock).mockResolvedValue(null);

            const result = await addCardToDeck(USER_ID, DECK_ID, { scryfallId: SCRYFALL_ID });

            expect(ensureCardInDb).toHaveBeenCalledWith(SCRYFALL_ID);
            expect(result.formatWarning).toBeNull();
            expect(result.card.formatWarning).toBeNull();
        });

        test('propaguje błąd gdy ensureCardInDb nie znajdzie karty', async () => {
            (getByIdForUser as jest.Mock).mockResolvedValue(deckMeta);
            (ensureCardInDb as jest.Mock).mockRejectedValue(new Error('Card not found'));

            await expect(
                addCardToDeck(USER_ID, DECK_ID, { scryfallId: SCRYFALL_ID }),
            ).rejects.toThrow('Card not found');

            expect(addCardToDeckForUser).not.toHaveBeenCalled();
        });

    });

    describe('getDeckDetails', () => {
        test('dołącza formatWarning do każdej karty', async () => {
            (getByIdForUserWithCards as jest.Mock).mockResolvedValue({
                ...deckMeta,
                cards: [deckCardRecord],
            });
            (getWarningsForDeckCards as jest.Mock).mockResolvedValue(
                new Map([
                    [SCRYFALL_ID, {
                        status: 'not_legal',
                        message: 'Karta nie jest legalna w formacie Modern',
                    }],
                ]),
            );

            const details = await getDeckDetails(USER_ID, DECK_ID);

            expect(getWarningsForDeckCards).toHaveBeenCalledWith([SCRYFALL_ID], 'Modern');
            expect(details.cards[0].formatWarning).toEqual({
                status: 'not_legal',
                message: 'Karta nie jest legalna w formacie Modern',
            });
        });
    });
});
