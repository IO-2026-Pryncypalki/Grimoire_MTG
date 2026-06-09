import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import Collection, { CollectionFilters } from '../collection/Collection';
import Card from '../collection/Card';
import { Card as CardModel } from '../models/Card';
import ScryfallAdapter from '../adapters/ScryfallAdapter';
import { ensureCardInDb } from '../services/CardService';
import type { CardCondition } from '../models/CollectionEntry';
import { publishSyncForUser } from '../services/syncPublish';
import { listAssignmentsForCollectionEntry } from '../repositories/DeckCardAssignmentRepository';

const router = Router();

const VALID_CONDITIONS: CardCondition[] = ['M', 'NM', 'GD', 'LP', 'MP', 'HP', 'DMG'];
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function parseAddToCollectionBody(body: Record<string, unknown>): {
    ok: true;
    scryfallId: string;
    quantity: number;
    condition: CardCondition;
    isFoil: boolean;
} | { ok: false; message: string } {
    const { scryfallId, quantity, condition, isFoil } = body;

    if (typeof scryfallId !== 'string' || !UUID_RE.test(scryfallId)) {
        return { ok: false, message: 'scryfallId must be a valid UUID' };
    }

    const parsedQuantity = quantity === undefined ? 1 : quantity;
    if (
        typeof parsedQuantity !== 'number' ||
        !Number.isInteger(parsedQuantity) ||
        parsedQuantity < 1
    ) {
        return { ok: false, message: 'quantity must be a positive integer' };
    }

    const parsedCondition = condition === undefined ? 'NM' : condition;
    if (
        typeof parsedCondition !== 'string' ||
        !VALID_CONDITIONS.includes(parsedCondition as CardCondition)
    ) {
        return { ok: false, message: 'condition is invalid' };
    }

    const parsedIsFoil = isFoil === undefined ? false : isFoil;
    if (typeof parsedIsFoil !== 'boolean') {
        return { ok: false, message: 'isFoil must be a boolean' };
    }

    return {
        ok: true,
        scryfallId,
        quantity: parsedQuantity,
        condition: parsedCondition as CardCondition,
        isFoil: parsedIsFoil,
    };
}

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
            collectionEntryId: entry.getId(),
            scryfallId: entry.getCard().getScryfallId(),
            name: entry.getCard().getName(),
            setCode: entry.getCard().getSetCode(),
            imageUrl: entry.getCard().getImageUrl(),
            imageUrlHiRes: entry.getCard().getImageUrlHiRes('grid'),
            price: entry.getCard().getCurrentPrice(),
            quantity: entry.getQuantity(),
            condition: entry.getCondition(),
            isFoil: entry.getIsFoil(),
            notes: entry.getNotes(),
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
        const validation = parseAddToCollectionBody(req.body);

        if (!validation.ok) {
            return res.status(400).json({ message: validation.message });
        }

        const { scryfallId, quantity, condition, isFoil } = validation;

        let cardModel: InstanceType<typeof CardModel>;
        try {
            cardModel = await ensureCardInDb(scryfallId);
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Failed to resolve card';
            if (message === 'Card not found') {
                return res.status(404).json({ message });
            }
            if (message === 'Scryfall Rate Limit Exceeded') {
                return res.status(429).json({ error: 'Scryfall Rate Limit Exceeded.' });
            }
            throw error;
        }

        const card = Card.fromModel(cardModel, isFoil);
        const collection = await Collection.load(user.id);
        const entry = await collection.addCardAndSave(card, { quantity, condition, isFoil });

        publishSyncForUser(user.id);

        return res.status(201).json({
            message: 'Card added to collection',
            entry,
        });
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

        publishSyncForUser(user.id);

        return res.status(200).json({
            message,
            ...refreshResult,
        });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to refresh prices', error });
    }
});

// GET /api/collection/entries/:entryId/assignments
router.get('/entries/:entryId/assignments', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as { id: string };
        const { entryId } = req.params;
        const assignments = await listAssignmentsForCollectionEntry(user.id, entryId);
        return res.status(200).json({
            assignments: assignments.map(a => ({
                deckId: a.deckId,
                deckName: a.deckName,
                quantity: a.quantity,
            })),
        });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to load entry assignments', error });
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
        await collection.transferCondition(scryfallId, fromCondition, toCondition, isFoil, quantity);

        publishSyncForUser(user.id);

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
            await collection.updateEntryQuantity(entry, delta);
            collection.pruneEmpty();
        }
        if (notes !== undefined) entry.setNotes(notes);

        publishSyncForUser(user.id);

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
        const removed = await collection.removeCard(scryfallId, condition, isFoil);
        if (removed === 0) {
            return res.status(404).json({ message: 'Entry not found' });
        }
        publishSyncForUser(user.id);
        return res.status(200).json({ message: 'Entry removed' });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Failed to remove entry';
        return res.status(500).json({ message });
    }
});

export default router;