import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import Collection from '../collection/Collection';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';

const router = Router();

// GET /api/collection
// Returns all entries in the authenticated user's collection
router.get('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const collection = await Collection.load(user.id);

        const entries = collection.getEntries().map(entry => ({
            scryfallId: entry.getCard().getScryfallId(),
            name:       entry.getCard().getName(),
            setCode:    entry.getCard().getSetCode(),
            imageUrl:   entry.getCard().getImageUrl(),
            price:      entry.getCard().getCurrentPrice(),
            quantity:   entry.getQuantity(),
            condition:  entry.getCondition(),
            isFoil:     entry.getIsFoil(),
            notes:      entry.getNotes(),
        }));

        return res.status(200).json({
            entries,
            totalValue: collection.calculateTotalValue(),
        });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to load collection', error });
    }
});

// POST /api/collection
// Adds a card to the collection (or increments quantity if it already exists)
// Body: { scryfallId, quantity?, condition?, isFoil? }
router.post('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId, quantity = 1, condition = 'NM', isFoil = false } = req.body;

        if (!scryfallId) {
            return res.status(400).json({ message: 'scryfallId is required' });
        }

        // Card must already exist in our cards table (populated via SmartAdapter)
        const cardModel = await CardModel.findByPk(scryfallId);
        if (!cardModel) {
            return res.status(404).json({ message: 'Card not found — fetch it via the search endpoint first' });
        }

        const card = Card.fromModel(cardModel as InstanceType<typeof CardModel>, isFoil);
        const collection = await Collection.load(user.id);
        await collection.addCard(card, { quantity, condition, isFoil });

        return res.status(201).json({ message: 'Card added to collection' });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to add card', error });
    }
});

// PATCH /api/collection/:scryfallId
// Updates quantity, condition, or notes on an existing entry
// Body: { delta?, condition?, notes? }
router.patch('/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId } = req.params;
        const { delta, condition, notes } = req.body;

        const collection = await Collection.load(user.id);

        let entry;
        try {
            entry = collection.getEntry(scryfallId);
        } catch {
            return res.status(404).json({ message: 'Card not in collection' });
        }

        if (delta !== undefined)     await entry.updateQuantity(delta);
        if (condition !== undefined) await entry.setCondition(condition);
        if (notes !== undefined)     await entry.setNotes(notes);

        return res.status(200).json({ message: 'Entry updated' });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to update entry', error });
    }
});

// DELETE /api/collection/:scryfallId
// Removes all entries for a card from the collection regardless of condition or foil
router.delete('/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId } = req.params;

        const collection = await Collection.load(user.id);
        await collection.removeCard(scryfallId);

        return res.status(200).json({ message: 'Card removed from collection' });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to remove card', error });
    }
});

export default router;