process.env.GOOGLE_CLIENT_ID = 'test-id';
process.env.GOOGLE_CLIENT_SECRET = 'test-secret';
process.env.FE_BASE_URL = 'http://localhost:5173';
process.env.JWT_SECRET = 'test-jwt-secret';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret';

import passport from 'passport';

let dynamicUser: { id: string; jwtSecureCode?: string } | undefined = {
    id: 'google-12345',
    jwtSecureCode: 'mock-uuid-789',
};

jest.spyOn(passport, 'authenticate').mockImplementation(() => {
    return (req: { user?: unknown }, _res: unknown, next: () => void) => {
        req.user = dynamicUser;
        next();
    };
});

import request from 'supertest';
import express from 'express';
import authRoute from '../src/backend/routes/authRoute';
import * as AuthService from '../src/backend/services/AuthService';

jest.mock('../src/backend/models/Session', () => ({
    Session: {
        create: jest.fn().mockResolvedValue({}),
    },
}));

jest.mock('../src/backend/services/AuthService');

const app = express();
app.use(express.json());
app.use(passport.initialize());
app.use('/api/auth', authRoute);

describe('Google Auth Flow', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        dynamicUser = { id: 'google-12345', jwtSecureCode: 'mock-uuid-789' };
    });

    it('should handle successful callback and redirect to frontend with cookies', async () => {
        (AuthService.getJwtTokens as jest.Mock).mockResolvedValue({
            accessToken: 'fake-access-token-123',
            refreshToken: 'fake-refresh-token-456',
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(302);
        expect(res.header.location).toBe(`${process.env.FE_BASE_URL}/`);

        const cookies = res.header['set-cookie'];
        expect(cookies).toBeDefined();
        expect(cookies.some((c: string) => c.includes('accessToken=fake-access-token-123'))).toBe(true);
        expect(cookies.some((c: string) => c.includes('refreshToken=fake-refresh-token-456'))).toBe(true);
        expect(res.header.location).not.toContain('accessToken=');
    });

    it('should return 401 if passport fails to provide user data', async () => {
        dynamicUser = undefined;

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(401);
        expect(res.body.message).toBe('Authentication failed');
    });

    it('should return 500 if AuthService fails', async () => {
        (AuthService.getJwtTokens as jest.Mock).mockImplementation(() => {
            throw new Error('Database down');
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(500);
        expect(res.body.message).toBe('An error occurred during authentication');
    });

    it('should redirect to / when FE_BASE_URL is empty', async () => {
        const originalUrl = process.env.FE_BASE_URL;
        process.env.FE_BASE_URL = '';

        (AuthService.getJwtTokens as jest.Mock).mockResolvedValue({
            accessToken: 'abc',
            refreshToken: 'szubidubi',
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(302);
        expect(res.header.location).toBe('/');
        expect(res.header.location).not.toContain('accessToken=');

        const cookies = res.header['set-cookie'];
        expect(cookies).toBeDefined();
        expect(cookies.some((c: string) => c.includes('accessToken=abc'))).toBe(true);

        process.env.FE_BASE_URL = originalUrl;
    });
});
