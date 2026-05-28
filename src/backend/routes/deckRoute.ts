import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import { DeckService } from '../services/DeckService';

const router = Router();

// GET /api/decks - Pobieranie wszystkich talii użytkownika
router.get('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const decks = await DeckService.getUserDecks(user.id);
        return res.status(200).json(decks);
    } catch (error: any) {
        return res.status(500).json({ message: error.message });
    }
});

// POST /api/decks - Tworzenie nowej talii
// Body: { name, format? }
router.post('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { name, format = 'Custom' } = req.body;

        if (!name) {
            return res.status(400).json({ message: 'Deck name is required' });
        }

        const newDeck = await DeckService.createDeck(user.id, name, format);
        return res.status(201).json(newDeck);
    } catch (error: any) {
        return res.status(500).json({ message: error.message });
    }
});

// GET /api/decks/:id - Pobieranie szczegółów talii
router.get('/:id', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const deckId = req.params.id;

        const deck = await DeckService.getDeckById(user.id, deckId);
        return res.status(200).json(deck);
    } catch (error: any) {
        if (error.message.includes('Not found')) {
            return res.status(404).json({ message: 'Deck not found' });
        }
        return res.status(500).json({ message: error.message });
    }
});

// POST /api/decks/:id/cards - Dodawanie kart do talii
// Body: { scryfallId, quantity?, board? }
router.post('/:id/cards', requireJwt, async (req: Request, res: Response) => {
    try {
        const deckId = req.params.id;
        const { scryfallId, quantity = 1, board = 'main' } = req.body;

        if (!scryfallId) {
            return res.status(400).json({ message: 'scryfallId is required' });
        }

        await DeckService.addCardToDeck(deckId, scryfallId, quantity, board);
        return res.status(201).json({ message: 'Card added to deck' });
    } catch (error: any) {
        return res.status(500).json({ message: error.message });
    }
});

// DELETE /api/decks/:id - Usuwanie talii
router.delete('/:id', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const deckId = req.params.id;

        await DeckService.deleteDeck(user.id, deckId);
        return res.status(200).json({ message: 'Deck deleted successfully' });
    } catch (error: any) {
        return res.status(500).json({ message: error.message });
    }
});

export default router;