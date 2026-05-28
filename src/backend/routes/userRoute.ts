import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import * as UserService from '../services/UserService';

const router = Router();

router.get('/',requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user as any;

        // Teraz await zadziała poprawnie
        const userInfo = await UserService.getUserProfile(user.id);

        return res.status(200).json(userInfo);
    } catch (error) {
        return res.status(500).json({ message: 'An error occurred', error });
    }
});

export default router;