import { Request, Response, Router } from 'express';
import passport from '../auth/passport';
import * as AuthService from '../services/AuthService';
import {Session}from '../models/Session'
import UserRoute from "../routes/userRoute";
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import {Model} from "sequelize";
import {getJwtTokens} from "../services/AuthService";
const router = Router();

router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));
router.get('/google/callback', passport.authenticate('google', { session: false }), async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        if (!user || !user.id) {
            return res.status(401).json({ message: "Authentication failed" });
        }
        // UWAGA: Dodajemy 'await' i wyciągamy oba tokeny
        const { accessToken, refreshToken } = await AuthService.getJwtTokens({
            id: user.id,
        });
        const hashedToken = await bcrypt.hash(refreshToken,10);
        const expiryDays = parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14',10);
       const expiresAt = new Date();
        const userAgent = req.headers['user-agent'] || '';
        // Prosty regex - jak znajdzie słowo 'android' albo 'mobile', to apka/telefon, jak nie, to web
        const deviceType = /android|mobile/i.test(userAgent) ? 'android' : 'web';
       expiresAt.setDate(expiresAt.getDate() + expiryDays)
        Session.create(
            {
                userId: user.id,
                refreshToken:hashedToken,
                device:deviceType,
                createdAt:new Date(),
                expiresAt

            }
        )
        res.cookie('refreshToken', refreshToken, {
            httpOnly: true, // Frontend (JS) nie ma do niego dostępu
            secure: process.env.NODE_ENV === 'production', // Wymaga HTTPS w produkcji
            sameSite: 'lax', // Zabezpieczenie przed atakami CSRF
            maxAge: parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14',10) * 24 * 60 * 60 * 1000
        });

        res.cookie('accessToken', accessToken, {
            httpOnly: false, // Frontend MUSI mieć do tego dostęp!
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: parseInt(process.env.ACCESS_TOKEN_EXPIRY_MIN || '15',10) * 60 * 1000 // 15 minut
        });
        // 3. Czysty redirect na frontend (bez brudzenia URL!)
        const redirectUrl = `${process.env.FE_BASE_URL}/api/user`;
        return res.status(302).redirect(redirectUrl);
    } catch (error) {
        return res.status(500).json({ message: 'An error occurred during authentication', error });
    }
});
router.post('/refresh', async(req : Request,res: Response)=>{

const {refreshToken} = req.cookies;
if ( !refreshToken) return res.sendStatus(401);
try {
    const payload = jwt.verify(refreshToken,process.env.JWT_REFRESH_SECRET)
    const sessions = await Session.findAll({where: {userId : payload.id}});
    let currentSession : any = null ;
    for ( const s of sessions)
    {
        const match = await bcrypt.compare(refreshToken,s.get('refreshToken'))
        if(match)
        {
            currentSession = s;
            break;
        }
    }
    if ( !currentSession || new Date() > currentSession.expiresAt)
    {
        return res.status(401).json({message:'Session expired you need to log in again'});
    }

    // Wszystko git generujemy nowy access token i rotujemy ten stary
      const {accessToken: newAccessToken,refreshToken: newRefreshToken} = await getJwtTokens({id:payload.id})

    res.cookie('accessToken',newAccessToken,{
        httpOnly:false,
        maxAge: parseInt(process.env.ACCESS_TOKEN_EXPIRY_MIN || '15',10) * 60 * 1000,
    })
    res.cookie('refreshToken', newRefreshToken, {
        httpOnly: true, // Frontend (JS) nie ma do niego dostępu
        secure: process.env.NODE_ENV === 'production', // Wymaga HTTPS w produkcji
        sameSite: 'lax', // Zabezpieczenie przed atakami CSRF
        maxAge: parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14',10) * 24 * 60 * 60 * 1000
    });
    const expiryDays = parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14',10);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expiryDays)
    await currentSession.update({
        refreshToken: await bcrypt.hash(newRefreshToken,10),
        created_at: new Date(),
        expiresAt
    })
    res.json({message:"Token refreshed"});
}
catch(err)
{
 res.sendStatus(401);
}
})
router.post('/logout',async (req: Request,res:Response)=>{
    const {refreshToken} = req.cookies;
    res.clearCookie('accessToken');
    res.clearCookie('refreshToken');

    if ( !refreshToken )
    {
        return res.status(200).json({message: 'You were logged out successfully'});
    }

    try {

        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET as string) as any;


        const sessions = await Session.findAll({ where: { userId: payload.id } });


        for (const s of sessions) {
            const match = await bcrypt.compare(refreshToken, s.get('refreshToken') as string);
            if (match) {
                await s.destroy();
                break;
            }
        }

        return res.status(200).json({ message: 'Pomyślnie wylogowano' });
    } catch (err) {
        return res.status(200).json({ message: 'Pomyślnie wylogowano (token wygasł)' });
    }
});
export default router;