import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import Collection, { CollectionFilters } from '../collection/Collection';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';
import ScryfallAdapter from '../adapters/ScryfallAdapter';

const router = Router();

function getQueryParam(value: unknown): string | undefined {
    if (typeof value === 'string') {
        const trimmed = value.trim();
        return trimmed.length > 0 ? trimmed : undefined;
    }

    if (Array.isArray(value) && typeof value[0] === 'string') {
        const trimmed = value[0].trim();
        return trimmed.length > 0 ? trimmed : undefined;
    }

    return undefined;
}

// GET /api/collection
router.get('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const color = getQueryParam(req.query.color)?.toUpperCase();
        const type = getQueryParam(req.query.type);
        const edition = getQueryParam(req.query.edition) ?? getQueryParam(req.query.setCode);
        const cmcParam = getQueryParam(req.query.cmc);

        let cmc: number | undefined;
        if (cmcParam !== undefined) {
            cmc = Number(cmcParam);
            if (Number.isNaN(cmc)) {
                return res.status(400).json({ message: 'cmc must be a valid number' });
            }
        }

        const filters: CollectionFilters = {};
        if (color) filters.color = color;
        if (type) filters.type = type;
        if (edition) filters.edition = edition;
        if (cmc !== undefined) filters.cmc = cmc;

        const collection = await Collection.load(user.id, filters);

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

// POST /api/collection/refresh-prices
router.post('/refresh-prices', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const collection = await Collection.load(user.id);
        const refreshResult = await collection.refreshPrices(new ScryfallAdapter());

        const message = refreshResult.totalCards === 0
            ? 'No cards to refresh'
            : refreshResult.failedCards > 0
                ? 'Prices refreshed with warnings'
                : 'Prices refreshed successfully';

        return res.status(200).json({
            message,
            ...refreshResult,
        });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to refresh prices', error });
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