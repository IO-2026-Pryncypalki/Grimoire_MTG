import { Request, Response, Router } from 'express';
import passport from '../auth/passport';
import * as AuthService from '../services/AuthService';
import { Session } from '../models/Session';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { getJwtTokens } from '../services/AuthService';

const router = Router();

const MOBILE_OAUTH_STATE = 'mobile';
const MOBILE_SCHEME = process.env.MOBILE_AUTH_SCHEME || 'grimoire';

const webFrontendRedirectUrl = (): string => {
    const base = (process.env.FE_BASE_URL || '').replace(/\/$/, '');
    return base.length > 0 ? `${base}/` : '/';
};

const webFrontendRedirectWithTokens = (
    accessToken: string,
    refreshToken: string,
): string => {
    const fragment = `accessToken=${encodeURIComponent(accessToken)}&refreshToken=${encodeURIComponent(refreshToken)}`;
    return `${webFrontendRedirectUrl()}#${fragment}`;
};

async function createSessionAndTokens(
    userId: string,
    userAgent: string,
): Promise<{ accessToken: string; refreshToken: string }> {
    const { accessToken, refreshToken } = await AuthService.getJwtTokens({ id: userId });
    const hashedToken = await bcrypt.hash(refreshToken, 10);
    const expiryDays = parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14', 10);
    const expiresAt = new Date();
    const deviceType = /android|mobile|flutter/i.test(userAgent) ? 'mobile' : 'web';
    expiresAt.setDate(expiresAt.getDate() + expiryDays);

    await Session.create({
        userId,
        refreshToken: hashedToken,
        device: deviceType,
        expiresAt,
    });

    return { accessToken, refreshToken };
}

function setAuthCookies(res: Response, accessToken: string, refreshToken: string) {
    res.cookie('refreshToken', refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14', 10) * 24 * 60 * 60 * 1000,
    });

    res.cookie('accessToken', accessToken, {
        httpOnly: false,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: parseInt(process.env.ACCESS_TOKEN_EXPIRY_MIN || '15', 10) * 60 * 1000,
    });
}

async function rotateRefreshToken(
    refreshToken: string,
    res: Response,
): Promise<{ ok: true; accessToken: string; refreshToken: string } | { ok: false }> {
    try {
        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET!) as { id: string };
        const sessions = await Session.findAll({ where: { userId: payload.id } });
        let currentSession: InstanceType<typeof Session> | null = null;

        for (const s of sessions) {
            const match = await bcrypt.compare(refreshToken, s.get('refreshToken') as string);
            if (match) {
                currentSession = s;
                break;
            }
        }

        if (!currentSession || new Date() > (currentSession.get('expiresAt') as Date)) {
            return { ok: false };
        }

        const { accessToken: newAccessToken, refreshToken: newRefreshToken } = await getJwtTokens({
            id: payload.id,
        });

        setAuthCookies(res, newAccessToken, newRefreshToken);

        const expiryDays = parseInt(process.env.REFRESH_TOKEN_EXPIRY_DAYS || '14', 10);
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + expiryDays);
        await currentSession.update({
            refreshToken: await bcrypt.hash(newRefreshToken, 10),
            expiresAt,
        });

        return { ok: true, accessToken: newAccessToken, refreshToken: newRefreshToken };
    } catch {
        return { ok: false };
    }
}

router.get('/google', (req: Request, res: Response, next) => {
    console.log('[auth] /google -> initiating web OAuth flow');
    passport.authenticate('google', { scope: ['profile', 'email'] })(req, res, next);
});

router.get('/google/mobile', (req: Request, res: Response, next) => {
    console.log('[auth] /google/mobile -> initiating mobile OAuth flow');
    passport.authenticate('google', { scope: ['profile', 'email'], state: MOBILE_OAUTH_STATE })(req, res, next);
});

router.get(
    '/google/callback',
    (req: Request, res: Response, next) => {
        console.log('[auth] /google/callback hit');
        console.log('[auth]   query.state  :', req.query.state);
        console.log('[auth]   query.code   :', req.query.code ? '<present>' : '<missing>');
        console.log('[auth]   query.error  :', req.query.error ?? 'none');
        console.log('[auth]   user-agent   :', req.headers['user-agent']);
        passport.authenticate('google', { session: false })(req, res, next);
    },
    async (req: Request, res: Response) => {
        try {
            const user = req.user as { id?: string } | undefined;
            console.log('[auth]   passport user id:', user?.id ?? 'MISSING');
            if (!user?.id) {
                console.warn('[auth]   Authentication failed - no user id after passport');
                return res.status(401).json({ message: 'Authentication failed' });
            }

            const userAgent = req.headers['user-agent'] || '';
            const { accessToken, refreshToken } = await createSessionAndTokens(user.id, userAgent);

            const isMobileFlow = req.query.state === MOBILE_OAUTH_STATE;
            console.log(`[auth]   isMobileFlow: ${isMobileFlow} (state="${req.query.state}", expected="${MOBILE_OAUTH_STATE}")`);

            if (isMobileFlow) {
                const redirectUrl = `${MOBILE_SCHEME}://auth?accessToken=${encodeURIComponent(accessToken)}&refreshToken=${encodeURIComponent(refreshToken)}`;
                console.log('[auth]   -> serving mobile redirect page for scheme:', redirectUrl.replace(/accessToken=[^&]+/, 'accessToken=<token>').replace(/refreshToken=[^&]+/, 'refreshToken=<token>'));
                return res.status(200).send(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0;url=${redirectUrl}">
  <title>Returning to app…</title>
  <style>
    body { font-family: sans-serif; display: flex; flex-direction: column;
           align-items: center; justify-content: center; min-height: 100vh;
           margin: 0; background: #1a1a2e; color: #e0e0e0; }
    a { color: #a78bfa; font-size: 1.1rem; margin-top: 16px; }
  </style>
</head>
<body>
  <p>Returning to Grimoire…</p>
  <a href="${redirectUrl}">Tap here if not redirected automatically</a>
  <script>window.location.replace(${JSON.stringify(redirectUrl)});</script>
</body>
</html>`);
            }

            console.log('[auth]   -> redirecting to web frontend');
            setAuthCookies(res, accessToken, refreshToken);
            return res.status(302).redirect(webFrontendRedirectWithTokens(accessToken, refreshToken));
        } catch (error) {
            console.error('[auth]   ERROR during callback:', error);
            return res.status(500).json({ message: 'An error occurred during authentication', error });
        }
    },
);

router.get('/session', (req: Request, res: Response) => {
    const hasCookie = Boolean(req.cookies?.accessToken);
    return res.status(200).json({ authenticated: hasCookie });
});

router.post('/refresh', async (req: Request, res: Response) => {
    const { refreshToken } = req.cookies;
    if (!refreshToken) return res.sendStatus(401);

    const result = await rotateRefreshToken(refreshToken, res);
    if (!result.ok) return res.sendStatus(401);

    return res.json({ message: 'Token refreshed' });
});

router.post('/refresh/mobile', async (req: Request, res: Response) => {
    const refreshToken =
        typeof req.body?.refreshToken === 'string' ? req.body.refreshToken : undefined;
    if (!refreshToken) return res.sendStatus(401);

    const result = await rotateRefreshToken(refreshToken, res);
    if (!result.ok) return res.sendStatus(401);

    return res.status(200).json({
        message: 'Token refreshed',
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
    });
});

router.post('/logout', async (req: Request, res: Response) => {
    const refreshToken = req.cookies?.refreshToken ?? req.body?.refreshToken;
    res.clearCookie('accessToken');
    res.clearCookie('refreshToken');

    if (!refreshToken) {
        return res.status(200).json({ message: 'You were logged out successfully' });
    }

    try {
        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET as string) as {
            id: string;
        };
        const sessions = await Session.findAll({ where: { userId: payload.id } });

        for (const s of sessions) {
            const match = await bcrypt.compare(refreshToken, s.get('refreshToken') as string);
            if (match) {
                await s.destroy();
                break;
            }
        }

        return res.status(200).json({ message: 'Pomyślnie wylogowano' });
    } catch {
        return res.status(200).json({ message: 'Pomyślnie wylogowano (token wygasł)' });
    }
});

export default router;
