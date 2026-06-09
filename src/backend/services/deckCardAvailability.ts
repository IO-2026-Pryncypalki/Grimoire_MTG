import { Card as CardModel } from '../models/Card';
import {
    getDeckQuantityByCardName,
    getOwnedQuantityByCardName,
    listDecksUsingCardName,
    type DeckUsingCardRecord,
} from '../repositories/DeckCardAssignmentRepository';
import { type DeckBoard } from '../repositories/DeckRepository';
import { DeckCard as DeckCardModel } from '../models/DeckCard';
import { Deck as DeckModel } from '../models/Deck';

export const EXCEEDS_OWNED_COLLECTION_QUANTITY = 'Exceeds owned collection quantity';

export interface CardAvailability {
    ownedQty: number;
    inDecksQty: number;
    availableToAdd: number;
    decksUsing: DeckUsingCardRecord[];
}

export const assertCanAddCardQuantityByName = async (
    userId: string,
    cardName: string,
    quantityToAdd: number,
): Promise<void> => {
    const owned = await getOwnedQuantityByCardName(userId, cardName);
    if (owned <= 0) {
        return;
    }

    const inDecks = await getDeckQuantityByCardName(userId, cardName);
    if (inDecks + quantityToAdd > owned) {
        throw new Error(EXCEEDS_OWNED_COLLECTION_QUANTITY);
    }
};

export const getCardAvailabilityByName = async (
    userId: string,
    cardName: string,
): Promise<CardAvailability> => {
    const ownedQty = await getOwnedQuantityByCardName(userId, cardName);
    const inDecksQty = await getDeckQuantityByCardName(userId, cardName);
    const decksUsing = await listDecksUsingCardName(userId, cardName);

    return {
        ownedQty,
        inDecksQty,
        availableToAdd: ownedQty > 0 ? Math.max(0, ownedQty - inDecksQty) : 0,
        decksUsing,
    };
};

export const getCardAvailabilityByScryfallId = async (
    userId: string,
    scryfallId: string,
): Promise<CardAvailability | null> => {
    const card = await CardModel.findByPk(scryfallId);
    if (!card) {
        return null;
    }

    const name = card.get('name') as string | null;
    if (!name) {
        return {
            ownedQty: 0,
            inDecksQty: 0,
            availableToAdd: 0,
            decksUsing: [],
        };
    }

    return getCardAvailabilityByName(userId, name);
};

export const findExistingDeckCardSlot = async (
    deckId: string,
    userId: string,
    scryfallId: string,
    board: DeckBoard,
): Promise<{ id: string; quantity: number } | null> => {
    const row = await DeckCardModel.findOne({
        where: { deckId, scryfallId, board },
        include: [
            {
                model: DeckModel,
                required: true,
                where: { userId },
            },
        ],
    });

    if (!row) {
        return null;
    }

    const raw = row.get() as Record<string, unknown>;
    return {
        id: raw.id as string,
        quantity: raw.quantity as number,
    };
};
