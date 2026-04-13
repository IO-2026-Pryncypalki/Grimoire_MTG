import { Request, Response, Router } from 'express';
import passport from '../auth/passport';
import * as AuthService from '../services/AuthService';

const router = Router();

/*
  This route triggers the Google sign-in/sign-up flow. 
  When the frontend calls it, the user will be redirected to the 
  Google accounts page to log in with their Google account.
*/
// Google OAuth2.0 route
router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));


/*
  This route is the callback endpoint for Google OAuth2.0. 
  After the user logs in via Google's authentication flow, they are redirected here.
  Passport.js processes the callback, attaches the user to req.user, and we handle 
  the access token generation and redirect the user to the frontend.
*/
// Google OAuth2.0 callback route
router.get('/google/callback', passport.authenticate('google', { session: false }), async (req: Request, res: Response) => {
    try {
        const user = req.user as any;
        if (!user || !user.id) {
            return res.status(401).json({ message: "Authentication failed" });
        }

        // UWAGA: Dodajemy 'await' i wyciągamy oba tokeny
        const { accessToken, refreshToken } = await AuthService.handleGoogleCallback({
            id: user.id,
            jwtSecureCode: user.jwtSecureCode
        });

        // BEZPIECZEŃSTWO: Ustawiamy refreshToken jako ciasteczko HttpOnly
        res.cookie('refreshToken', refreshToken, {
            httpOnly: true, // Frontend (JS) nie ma do niego dostępu
            secure: process.env.NODE_ENV === 'production', // Wymaga HTTPS w produkcji
            sameSite: 'lax', // Zabezpieczenie przed atakami CSRF
            maxAge: 14 * 24 * 60 * 60 * 1000 // 14 dni w milisekundach
        });

        // redirect to frontend with the accessToken as query param
        const redirectUrl = `${process.env.FE_BASE_URL}?accessToken=${accessToken}`;
        return res.status(302).redirect(redirectUrl);

    } catch (error) {
        return res.status(500).json({ message: 'An error occurred during authentication', error });
    }
});

export default router;