import { formatDeckList, type DeckListCardInput } from '../scanner/formatDeckList';
import { getDeckDetails } from './DeckService';

export const exportDeckToList = async (userId: string, deckId: string): Promise<string> => {
    const deck = await getDeckDetails(userId, deckId);

    const cards: DeckListCardInput[] = deck.cards.map((card) => ({
        name: card.name?.trim() || card.scryfallId,
        quantity: card.quantity,
        board: card.board,
    }));

    return formatDeckList(cards, deck.format);
};
