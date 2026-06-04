import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import * as DeckService from '../services/DeckService';
import * as AssignmentService from '../services/DeckCardAssignmentService';
import { type DeckBoard, type DeckFormat } from '../repositories/DeckRepository';
import { publishSyncForUser } from '../services/syncPublish';

const router = Router();

const ALLOWED_FORMATS: DeckFormat[] = [
    'Standard',
    'Pioneer',
    'Modern',
    'Legacy',
    'Vintage',
    'Commander',
    'Pauper',
    'Draft',
    'Sealed',
    'Oathbreaker',
    'Custom',
];

const isDeckFormat = (value: unknown): value is DeckFormat =>
    typeof value === 'string' && ALLOWED_FORMATS.includes(value as DeckFormat);

const ALLOWED_BOARDS: DeckBoard[] = ['main', 'sideboard', 'commander'];

const isDeckBoard = (value: unknown): value is DeckBoard =>
    typeof value === 'string' && ALLOWED_BOARDS.includes(value as DeckBoard);

type ValidationResult =
    | { ok: true }
    | { ok: false; message: string };

const ASSIGNMENT_ERROR_MESSAGES = new Set([
    'Collection entry not found',
    'Scryfall ID mismatch',
    'Card name mismatch',
    'Deck card has no name',
    'Exceeds deck slot quantity',
    'Exceeds collection entry quantity',
    'Cannot reduce deck card below assigned quantity',
    'Assignment not found',
    'Deck card not found',
]);

const mapDeckServiceError = (error: unknown, res: Response, fallbackMessage: string) => {
    const message = error instanceof Error ? error.message : fallbackMessage;

    if (message === 'Deck not found') {
        return res.status(404).json({ message });
    }
    if (message === 'Scryfall Rate Limit Exceeded') {
        return res.status(429).json({ error: 'Scryfall Rate Limit Exceeded.' });
    }
    if (
        message === 'Deck name must not be empty' ||
        message === 'Invalid lastValidatedAt date' ||
        message === 'quantity must be greater than 0' ||
        ASSIGNMENT_ERROR_MESSAGES.has(message)
    ) {
        return res.status(400).json({ message });
    }
    if (message === 'Card not found' || message === 'Deck card not found') {
        return res.status(404).json({ message });
    }

    return res.status(500).json({ message: fallbackMessage, error });
};

const parsePositiveQuantity = (
    value: unknown,
    fieldName: string,
): number | { ok: false; message: string } => {
    if (value === undefined) {
        return 1;
    }

    const quantity = typeof value === 'string' ? Number(value) : value;
    if (typeof quantity !== 'number' || !Number.isInteger(quantity) || quantity <= 0) {
        return { ok: false, message: `${fieldName} must be a positive integer` };
    }

    return quantity;
};

const validateCreateBody = (body: Record<string, unknown>): ValidationResult => {
    const { name, format, description } = body;

    if (typeof name !== 'string' || name.trim().length === 0) {
        return { ok: false, message: 'name is required' };
    }

    if (format !== undefined && !isDeckFormat(format)) {
        return { ok: false, message: 'format is invalid' };
    }

    if (description !== undefined && description !== null && typeof description !== 'string') {
        return { ok: false, message: 'description must be a string or null' };
    }

    return { ok: true };
};

const validateUpdateBody = (body: Record<string, unknown>): ValidationResult => {
    const { name, format, description, isValid, lastValidatedAt } = body;
    const hasAnyField = [name, format, description, isValid, lastValidatedAt].some(
        (value) => value !== undefined,
    );

    if (!hasAnyField) {
        return { ok: false, message: 'at least one field is required' };
    }

    if (name !== undefined && (typeof name !== 'string' || name.trim().length === 0)) {
        return { ok: false, message: 'name must be a non-empty string' };
    }

    if (format !== undefined && !isDeckFormat(format)) {
        return { ok: false, message: 'format is invalid' };
    }

    if (description !== undefined && description !== null && typeof description !== 'string') {
        return { ok: false, message: 'description must be a string or null' };
    }

    if (isValid !== undefined && isValid !== null && typeof isValid !== 'boolean') {
        return { ok: false, message: 'isValid must be a boolean or null' };
    }

    if (
        lastValidatedAt !== undefined &&
        lastValidatedAt !== null &&
        (typeof lastValidatedAt !== 'string' || Number.isNaN(new Date(lastValidatedAt).getTime()))
    ) {
        return { ok: false, message: 'lastValidatedAt must be a valid ISO date string or null' };
    }

    return { ok: true };
};

type AssignmentInput = { collectionEntryId: string; quantity: number };

const parseAssignments = (
    value: unknown,
): AssignmentInput[] | { ok: false; message: string } => {
    if (value === undefined) {
        return [];
    }
    if (!Array.isArray(value)) {
        return { ok: false, message: 'assignments must be an array' };
    }

    const parsed: AssignmentInput[] = [];
    for (const item of value) {
        if (typeof item !== 'object' || item === null) {
            return { ok: false, message: 'each assignment must be an object' };
        }
        const record = item as Record<string, unknown>;
        if (typeof record.collectionEntryId !== 'string' || record.collectionEntryId.trim().length === 0) {
            return { ok: false, message: 'collectionEntryId is required in each assignment' };
        }
        const qty = parsePositiveQuantity(record.quantity, 'assignment quantity');
        if (typeof qty !== 'number') {
            return qty;
        }
        parsed.push({ collectionEntryId: record.collectionEntryId.trim(), quantity: qty });
    }
    return parsed;
};

type AddCardBodyValidation =
    | { ok: false; message: string }
    | { scryfallId: string; quantity: number; board: DeckBoard; assignments: AssignmentInput[] };

const validateAddCardBody = (body: Record<string, unknown>): AddCardBodyValidation => {
    const { scryfallId, quantity, board, assignments } = body;

    if (typeof scryfallId !== 'string' || scryfallId.trim().length === 0) {
        return { ok: false, message: 'scryfallId is required' };
    }

    const parsedQuantity = parsePositiveQuantity(quantity, 'quantity');
    if (typeof parsedQuantity !== 'number') {
        return parsedQuantity;
    }

    if (board !== undefined && !isDeckBoard(board)) {
        return { ok: false, message: 'board is invalid' };
    }

    const parsedAssignments = parseAssignments(assignments);
    if ('ok' in parsedAssignments) {
        return parsedAssignments;
    }

    const assignmentTotal = parsedAssignments.reduce((sum, a) => sum + a.quantity, 0);
    if (assignmentTotal > parsedQuantity) {
        return { ok: false, message: 'Exceeds deck slot quantity' };
    }

    return {
        scryfallId: scryfallId.trim(),
        quantity: parsedQuantity,
        board: board ?? 'main',
        assignments: parsedAssignments,
    };
};

const validateAssignmentBody = (
    body: Record<string, unknown>,
): { collectionEntryId: string; quantity: number } | { ok: false; message: string } => {
    const { collectionEntryId, quantity } = body;
    if (typeof collectionEntryId !== 'string' || collectionEntryId.trim().length === 0) {
        return { ok: false, message: 'collectionEntryId is required' };
    }
    const parsedQuantity = parsePositiveQuantity(quantity, 'quantity');
    if (typeof parsedQuantity !== 'number') {
        return parsedQuantity;
    }
    return { collectionEntryId: collectionEntryId.trim(), quantity: parsedQuantity };
};

// GET /api/decks
router.get('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const decks = await DeckService.listDecks(user.id);
        return res.status(200).json({ decks });
    } catch (error) {
        return res.status(500).json({ message: 'Failed to load decks', error });
    }
});

// POST /api/decks
router.post('/', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const validation = validateCreateBody(req.body);

        if (!validation.ok) {
            return res.status(400).json({ message: validation.message });
        }

        const { name, format, description } = req.body;
        const deck = await DeckService.createDeck(user.id, {
            name,
            format,
            description,
        });

        publishSyncForUser(user.id);

        return res.status(201).json({
            message: 'Deck created',
            deck,
        });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to create deck');
    }
});

// POST /api/decks/:id/cards
router.post('/:id/cards', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const validation = validateAddCardBody(req.body);

        if ('ok' in validation) {
            return res.status(400).json({ message: validation.message });
        }

        const { scryfallId, quantity, board, assignments } = validation;

        const result = await DeckService.addCardToDeck(user.id, req.params.id, {
            scryfallId,
            quantity,
            board,
            assignments,
        });

        return res.status(201).json({
            message: 'Card added to deck',
            card: result.card,
            formatWarning: result.formatWarning,
        });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to add card to deck');
    }
});

// POST /api/decks/:id/assign-from-collection-by-name
router.post(
    '/:id/assign-from-collection-by-name',
    requireJwt,
    async (req: Request, res: Response) => {
        try {
            const user = req.user as any;
            const summary = await AssignmentService.assignDeckFromCollectionByName(
                user.id,
                req.params.id,
            );
            return res.status(200).json(summary);
        } catch (error) {
            return mapDeckServiceError(error, res, 'Failed to assign from collection by name');
        }
    },
);

// GET /api/decks/:id/cards/:deckCardId/collection-options
router.get(
    '/:id/cards/:deckCardId/collection-options',
    requireJwt,
    async (req: Request, res: Response) => {
        try {
            const user = req.user as any;
            const options = await AssignmentService.listCollectionOptionsForDeckCard(
                user.id,
                req.params.id,
                req.params.deckCardId,
            );
            return res.status(200).json({ options });
        } catch (error) {
            return mapDeckServiceError(error, res, 'Failed to load collection options');
        }
    },
);

// POST /api/decks/:id/cards/:deckCardId/assignments
router.post(
    '/:id/cards/:deckCardId/assignments',
    requireJwt,
    async (req: Request, res: Response) => {
        try {
            const user = req.user as any;
            const validation = validateAssignmentBody(req.body);
            if ('ok' in validation) {
                return res.status(400).json({ message: validation.message });
            }

            const fillStatus = await AssignmentService.assignCollectionEntry(
                user.id,
                req.params.id,
                req.params.deckCardId,
                validation,
            );

            return res.status(201).json({
                message: 'Collection entry assigned to deck card',
                fillStatus,
            });
        } catch (error) {
            return mapDeckServiceError(error, res, 'Failed to assign collection entry');
        }
    },
);

// PATCH /api/decks/:id/cards/:deckCardId/assignments/:assignmentId
router.patch(
    '/:id/cards/:deckCardId/assignments/:assignmentId',
    requireJwt,
    async (req: Request, res: Response) => {
        try {
            const user = req.user as any;
            const parsedQuantity = parsePositiveQuantity(req.body.quantity, 'quantity');
            if (typeof parsedQuantity !== 'number') {
                return res.status(400).json({ message: parsedQuantity.message });
            }

            const fillStatus = await AssignmentService.updateAssignment(
                user.id,
                req.params.id,
                req.params.deckCardId,
                req.params.assignmentId,
                parsedQuantity,
            );

            return res.status(200).json({
                message: 'Assignment updated',
                fillStatus,
            });
        } catch (error) {
            return mapDeckServiceError(error, res, 'Failed to update assignment');
        }
    },
);

// DELETE /api/decks/:id/cards/:deckCardId/assignments/:assignmentId
router.delete(
    '/:id/cards/:deckCardId/assignments/:assignmentId',
    requireJwt,
    async (req: Request, res: Response) => {
        try {
            const user = req.user as any;
            const fillStatus = await AssignmentService.removeAssignment(
                user.id,
                req.params.id,
                req.params.deckCardId,
                req.params.assignmentId,
            );

            return res.status(200).json({
                message: 'Assignment removed',
                fillStatus,
            });
        } catch (error) {
            return mapDeckServiceError(error, res, 'Failed to remove assignment');
        }
    },
);

// DELETE /api/decks/:id/cards/:scryfallId
router.delete('/:id/cards/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const boardParam = req.query.board;
        const quantityParam = req.query.quantity;

        if (boardParam !== undefined && !isDeckBoard(boardParam)) {
            return res.status(400).json({ message: 'board is invalid' });
        }

        const parsedQuantity = parsePositiveQuantity(quantityParam, 'quantity');
        if (typeof parsedQuantity !== 'number') {
            return res.status(400).json({ message: parsedQuantity.message });
        }

        const result = await DeckService.removeCardFromDeck(
            user.id,
            req.params.id,
            req.params.scryfallId,
            {
                board: (boardParam as DeckBoard | undefined) ?? 'main',
                quantity: parsedQuantity,
            },
        );

        if (result.removed) {
            return res.status(200).json({ message: 'Card removed from deck' });
        }

        return res.status(200).json({
            message: 'Card quantity updated',
            card: result.card,
        });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to remove card from deck');
    }
});

// GET /api/decks/:id
router.get('/:id', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const deck = await DeckService.getDeckDetails(user.id, req.params.id);
        return res.status(200).json({ deck });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to load deck');
    }
});

// PATCH /api/decks/:id
router.patch('/:id', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        const validation = validateUpdateBody(req.body);

        if (!validation.ok) {
            return res.status(400).json({ message: validation.message });
        }

        const { name, format, description, isValid, lastValidatedAt } = req.body;
        const deck = await DeckService.updateDeck(user.id, req.params.id, {
            name,
            format,
            description,
            isValid,
            lastValidatedAt,
        });

        publishSyncForUser(user.id);

        return res.status(200).json({
            message: 'Deck updated',
            deck,
        });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to update deck');
    }
});

// DELETE /api/decks/:id
router.delete('/:id', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        await DeckService.removeDeck(user.id, req.params.id);
        publishSyncForUser(user.id);
        return res.status(200).json({ message: 'Deck removed' });
    } catch (error) {
        return mapDeckServiceError(error, res, 'Failed to remove deck');
    }
});

export default router;
