import { Deck, DeckFormat } from '../models/Deck';
import { DeckCard, DeckBoard } from '../models/DeckCard';
import {Card} from "../models/Card";

export class DeckService {

    // Tworzenie nowej pustej talii
    public static async createDeck(userId: string, name: string, format: DeckFormat): Promise<Deck> {
        return await Deck.create({
            userId,
            name,
            format,
            isValid: false
        });
    }

    // Pobieranie wszystkich talii użytkownika (wraz ze statystykami)
    public static async getUserDecks(userId: string): Promise<Deck[]> {
        return await Deck.findAll({
            where: {userId},
            order: [['updatedAt','DESC']]
        })
    }

    // Pobieranie pojedynczej talii (wraz z kartami w podziale na main/sideboard/commander)
    public static async getDeckById(userId: string, deckId: string): Promise<Deck> {
        const deck = await Deck.findOne({
            where: { id: deckId, userId },
            // Zaciągamy od razu karty przypisane do talii
            include: [{
                model: DeckCard,
                as: 'deckCards', // Musi pasować do aliasu z pliku asocjacji!
            }]
        });

        if (!deck) {
            throw new Error('Not found: Deck does not exist or belongs to another user');
        }

        return deck;
    }

    // Dodawanie karty do talii
    public static async addCardToDeck(deckId: string, scryfallId: string, quantity: number, board: DeckBoard): Promise<DeckCard> {
        // 1. Sprawdzamy czy karta w ogóle istnieje w naszej bazie (w tabeli cards)
        const cardExists = await Card.findByPk(scryfallId);
        if (!cardExists) {
            throw new Error('Card not found in database. Fetch it via search endpoint first.');
        }

        // 2. Szukamy czy ta karta już jest w tej konkretnej strefie (main/sideboard/commander) tej talii
        const existingDeckCard = await DeckCard.findOne({
            where: { deckId, scryfallId, board }
        });

        if (existingDeckCard) {
            // Jak jest, to po prostu zwiększamy ilość
            existingDeckCard.quantity += quantity;
            return await existingDeckCard.save();
        } else {
            // Jak nie ma, to dodajemy nowy wpis
            return await DeckCard.create({
                deckId,
                scryfallId,
                quantity,
                board
            });
        }
    }
    public static async removeCardFromDeck(deckId: string, scryfallId: string, board: DeckBoard = 'main', quantityToRemove?: number): Promise<void> {
        const deckCard = await DeckCard.findOne({
            where: { deckId, scryfallId, board }
        });

        if (!deckCard) {
            throw new Error('Card not found in this deck');
        }

        // Jeśli podano ile sztuk odjąć i zostaje nam ich jeszcze trochę w talii, to zmniejszamy licznik
        if (quantityToRemove && deckCard.quantity > quantityToRemove) {
            deckCard.quantity -= quantityToRemove;
            await deckCard.save();
        } else {
            // W przeciwnym razie (lub gdy nie podano ilości) wywalamy kartę z talii całkowicie
            await deckCard.destroy();
        }
    }
    public static async deleteDeck(userId: string, deckId: string): Promise<void> {
        const deletedRows = await Deck.destroy({
            where: { id: deckId, userId }
        });

        if (deletedRows === 0) {
            throw new Error('Not found: Deck does not exist or belongs to another user');
        }
        // Dzięki 'ON DELETE CASCADE' w bazie, rekordy w deck_cards polecą automatycznie
    }
}