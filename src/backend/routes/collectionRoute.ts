import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import Collection from '../collection/Collection';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';

const router = Router();

// GET /api/collection
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
// Body: { scryfallId, quantity?, condition?, isFoil? }
router.post('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId, quantity = 1, condition = 'NM', isFoil = false } = req.body;

        if (!scryfallId) {
            return res.status(400).json({ message: 'scryfallId is required' });
        }

        const cardModel = await CardModel.findByPk(scryfallId);
        if (!cardModel) {
            return res.status(404).json({ message: 'Card not found — fetch it via the search endpoint first' });
        }

        const card = Card.fromModel(cardModel as InstanceType<typeof CardModel>, isFoil);
        const collection = await Collection.load(user.id);
        collection.addCard(card, { quantity, condition, isFoil });

        return res.status(201).json({ message: 'Card added to collection' });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to add card', error });
    }
});

// PATCH /api/collection/:scryfallId/transfer
// Body: { fromCondition, toCondition, isFoil?, quantity? }
router.patch('/:scryfallId/transfer', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId } = req.params;
        const { fromCondition, toCondition, isFoil = false, quantity = 1 } = req.body;

        if (!fromCondition || !toCondition) {
            return res.status(400).json({ message: 'fromCondition and toCondition are required' });
        }

        const collection = await Collection.load(user.id);
        collection.transferCondition(scryfallId, fromCondition, toCondition, isFoil, quantity);

        return res.status(200).json({ message: 'Condition transferred' });
    } catch (error: any) {
        return res.status(400).json({ message: error.message });
    }
});

// PATCH /api/collection/:scryfallId?condition=NM&isFoil=false
// Body: { delta?, notes? }
router.patch('/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId } = req.params;
        const condition = req.query.condition as string | undefined;
        const isFoil    = req.query.isFoil === 'true'  ? true
                        : req.query.isFoil === 'false' ? false
                        : undefined;
        const { delta, notes } = req.body;

        const collection = await Collection.load(user.id);
        const entry = collection.getEntry(scryfallId, condition, isFoil);
        if (!entry) return res.status(404).json({ message: 'Entry not found' });

        if (delta !== undefined) {
            entry.updateQuantity(delta);
            collection.pruneEmpty();
        }
        if (notes !== undefined) entry.setNotes(notes);

        return res.status(200).json({ message: 'Entry updated' });
    } catch (error: any) {
        return res.status(400).json({ message: error.message });
    }
});

// DELETE /api/collection/:scryfallId?condition=NM&isFoil=false
router.delete('/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const { scryfallId } = req.params;
        const condition = req.query.condition as string | undefined;
        const isFoil    = req.query.isFoil === 'true'  ? true
                        : req.query.isFoil === 'false' ? false
                        : undefined;

        const collection = await Collection.load(user.id);
        collection.removeCard(scryfallId, condition, isFoil);
        return res.status(200).json({ message: 'Entry removed' });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to remove entry', error });
    }
});

export default router;