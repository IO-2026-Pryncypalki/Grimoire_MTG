import { Deck, DeckFormat } from '../models/Deck';
import { DeckCard, DeckBoard } from '../models/DeckCard';

export class DeckService {

    // Tworzenie nowej pustej talii
    public static async createDeck(userId: string, name: string, format: DeckFormat): Promise<Deck> {
        throw new Error('Not implemented yet - TDD Faza RED');
    }

    // Pobieranie wszystkich talii użytkownika (wraz ze statystykami)
    public static async getUserDecks(userId: string): Promise<any[]> {
        throw new Error('Not implemented yet - TDD Faza RED');
    }

    // Pobieranie pojedynczej talii (wraz z kartami w podziale na main/sideboard/commander)
    public static async getDeckById(userId: string, deckId: string): Promise<any> {
        throw new Error('Not implemented yet - TDD Faza RED');
    }

    // Dodawanie karty do talii
    public static async addCardToDeck(deckId: string, scryfallId: string, quantity: number, board: DeckBoard): Promise<void> {
        throw new Error('Not implemented yet - TDD Faza RED');
    }

    // Usuwanie talii (Dzięki CASCADE w bazie usunie też DeckCards)
    public static async deleteDeck(userId: string, deckId: string): Promise<void> {
        throw new Error('Not implemented yet - TDD Faza RED');
    }
}