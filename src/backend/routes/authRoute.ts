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

router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));

router.get(
    '/google/mobile',
    passport.authenticate('google', { scope: ['profile', 'email'], state: MOBILE_OAUTH_STATE }),
);

router.get(
    '/google/callback',
    passport.authenticate('google', { session: false }),
    async (req: Request, res: Response) => {
        try {
            const user = req.user as { id?: string } | undefined;
            if (!user?.id) {
                return res.status(401).json({ message: 'Authentication failed' });
            }

            const userAgent = req.headers['user-agent'] || '';
            const { accessToken, refreshToken } = await createSessionAndTokens(user.id, userAgent);

            const isMobileFlow = req.query.state === MOBILE_OAUTH_STATE;

            if (isMobileFlow) {
                const redirectUrl = `${MOBILE_SCHEME}://auth?accessToken=${encodeURIComponent(accessToken)}&refreshToken=${encodeURIComponent(refreshToken)}`;
                return res.status(302).redirect(redirectUrl);
            }

            setAuthCookies(res, accessToken, refreshToken);
            return res.status(302).redirect(webFrontendRedirectWithTokens(accessToken, refreshToken));
        } catch (error) {
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
