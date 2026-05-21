import { Request, Response, Router } from 'express';
import requireJwt from '../middlewares/requireJwt';
import * as UserService from '../services/UserService'; // Zmienione na import *

const router = Router();

// Musimy dodać 'async' przed (req, res), żeby await działał
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
router.get('/collection/',requireJwt,async(req:Request,res:Response)=>{
try {
    
}
catch(err)
{
    return res.status(500).json({message: 'An error occured',err});
}
})
router.get('/decks/',requireJwt,async(req: Request,res: Response)=>{

})


export default router;