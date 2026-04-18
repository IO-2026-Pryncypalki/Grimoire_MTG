import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';

import ScryfallAdapter from "../adapters/ScryfallAdapter";
const router = Router()

const scryfall = new ScryfallAdapter();
router.get('/search',async (req,res)=>{
    const cardData = await scryfall.searchCard('Black Lotus')
    res.send(cardData)
});
export default router