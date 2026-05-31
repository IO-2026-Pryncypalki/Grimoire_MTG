import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import * as UserService from '../services/UserService'; // Zmienione na import *
import {User} from '../models/User'
import {Deck} from '../models/Deck'
import {CollectionEntry} from '../models/CollectionEntry'

const router = Router();

// GET /api/user/me
router.get('/me', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user;

        // 1. Liczymy talie
        const deckCount = await Deck.count({
            where: { userId: user.id }
        });

        // 2. Liczymy unikalne wpisy w kolekcji (ile różnych kart)
        const uniqueCardsCount = await CollectionEntry.count({
            where: { userId: user.id }
        });

        // 3. Liczymy łączną ilość fizycznych kart (sumujemy kolumnę 'quantity')
        // Używamy "|| 0", bo sum() zwraca null, jeśli nie ma żadnych kart
        const totalPhysicalCards = await CollectionEntry.sum('quantity', {
            where: { userId: user.id }
        }) || 0;

        // Zwracamy piękny, spakowany obiekt
        return res.status(200).json({
            username: user.username,
            email: user.email,
            stats: {
                deckCount,
                uniqueCardsCount,
                totalPhysicalCards,
                joinedAt: new Date(user.createdAt).toLocaleDateString('pl-PL')
            }
        });
    } catch (error) {
        console.error("Błąd podczas pobierania profilu:", error);
        return res.status(500).json({ message: 'Error fetching user profile', error });
    }
});

// PATCH /api/user/me (Edycja danych)
router.patch('/me', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user;
        const { username } = req.body;

        if (username) {
            user.username = username;
            await user.save();
        }

        return res.status(200).json({ message: 'Profile updated', user });
    } catch (error) {
        return res.status(500).json({ message: 'Error updating profile', error });
    }
});
router.delete('/me', requireJwt, async (req: Request, res: Response) => {
    try {
        const user = req.user;

        await user.destroy();

        res.clearCookie('accessToken');
        res.clearCookie('refreshToken');

        return res.status(200).json({ message: 'Account deleted successfully, but we hope you will be back.' });
    } catch (error) {
        console.error("Error:", error);
        return res.status(500).json({ message: 'Error.', error });
    }
});
export default router;