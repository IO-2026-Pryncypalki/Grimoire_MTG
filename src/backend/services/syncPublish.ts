import { Deck } from '../models/Deck';
import * as SyncEventHub from './SyncEventHub';

export const publishSyncForUser = (userId: string): void => {
    void SyncEventHub.publish(userId).catch((err) => {
        console.error('publishSyncForUser failed:', err);
    });
};

export const publishSyncForDeck = async (deckId: string): Promise<void> => {
    const deck = await Deck.findByPk(deckId, { attributes: ['userId'] });
    if (!deck) return;
    const userId = deck.get('userId') as string;
    await SyncEventHub.publish(userId);
};
