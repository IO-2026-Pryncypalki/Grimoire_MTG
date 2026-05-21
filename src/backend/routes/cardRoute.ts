import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';

import ScryfallAdapter from "../adapters/ScryfallAdapter";
import Card from "../collection/Card";
const router = Router()

const scryfall = new ScryfallAdapter();
router.post('/search',async (req,res)=> {
    try {
        const { cardName } = req.body;

        const cardData = await scryfall.searchCard(cardName);

        return res.status(201).json({
            data: cardData
        });

    } catch (error: any) {
        if (error.message === "Scryfall Rate Limit Exceeded") {
            return res.status(429).json({ error: "Scryfall Rate Limit Exceeded." });
        }

        return res.status(500).json({ error: error.message });
    }
});
export default router