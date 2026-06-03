import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import { getSyncStatusForUser } from '../services/SyncService';

const router = Router();

router.get('/status', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as { id: string };
        const status = await getSyncStatusForUser(user.id);
        return res.status(200).json(status);
    } catch (error) {
        return res.status(500).json({ message: 'Failed to load sync status', error });
    }
});

export default router;
