import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import { SymbologyCache } from '../scanner/symbologyCache';

export function createSymbologyRoute(cache: SymbologyCache): Router {
    const router = Router();

    router.get('/', requireJwt, (_req: Request, res: Response) => {
        res.json({ symbols: cache.toList() });
    });

    return router;
}
