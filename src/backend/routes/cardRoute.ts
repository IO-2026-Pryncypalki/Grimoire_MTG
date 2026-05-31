import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import ScannerService from '../scanner/ScannerService';
import { toCardDetailDto, toCardDto } from '../scanner/cardResponseDto';
import { getCardDetails, searchCards } from '../services/CardService';

const router = Router();

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const scannerService = new ScannerService();

const mapScryfallError = (error: unknown, res: Response, fallback: string) => {
    const message = error instanceof Error ? error.message : fallback;

    if (message === 'cardName is required') {
        return res.status(400).json({ error: message });
    }
    if (message === 'Scryfall Rate Limit Exceeded') {
        return res.status(429).json({ error: 'Scryfall Rate Limit Exceeded.' });
    }
    if (message === 'Card not found') {
        return res.status(404).json({ error: message });
    }

    return res.status(500).json({ error: message });
};

router.post('/search', requireJwt, async (req: Request, res: Response) => {
    try {
        const { cardName } = req.body;

        if (typeof cardName !== 'string') {
            return res.status(400).json({ error: 'cardName is required' });
        }

        const result = await searchCards(cardName);

        return res.status(200).json({
            cards: result.cards.map(toCardDto),
            total: result.total,
        });
    } catch (error: unknown) {
        return mapScryfallError(error, res, 'Search failed');
    }
});

router.post('/scan', requireJwt, async (req: Request, res: Response) => {
    try {
        const { plaintext } = req.body;

        if (typeof plaintext !== 'string') {
            return res.status(400).json({ error: 'plaintext is required' });
        }

        const result = await scannerService.scanFromPlaintext(plaintext);

        return res.status(200).json({
            resolution: result.resolution,
            parsed: result.parsed,
            cards: result.cards.map(toCardDto),
            total: result.total,
        });
    } catch (error: unknown) {
        const message = error instanceof Error ? error.message : 'Scan failed';

        if (message === 'Plaintext is required') {
            return res.status(400).json({ error: message });
        }
        if (message === 'Scryfall Rate Limit Exceeded') {
            return res.status(429).json({ error: 'Scryfall Rate Limit Exceeded.' });
        }

        return res.status(500).json({ error: message });
    }
});

router.get('/:scryfallId', requireJwt, async (req: Request, res: Response) => {
    try {
        const { scryfallId } = req.params;

        if (!UUID_RE.test(scryfallId)) {
            return res.status(400).json({ error: 'scryfallId must be a valid UUID' });
        }

        const card = await getCardDetails(scryfallId);

        return res.status(200).json(toCardDetailDto(card));
    } catch (error: unknown) {
        return mapScryfallError(error, res, 'Failed to load card details');
    }
});

export default router;
