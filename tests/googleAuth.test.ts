process.env.GOOGLE_CLIENT_ID = 'test-id';
process.env.GOOGLE_CLIENT_SECRET = 'test-secret';
process.env.BE_BASE_URL = 'http://localhost:3000';
process.env.JWT_SECRET = 'test-jwt-secret';

import passport from 'passport';

// 1. DYNAMICZNY MOCK - Ta zmienna steruje zachowaniem Passporta w testach
let dynamicUser: any = { id: 'google-12345', jwtSecureCode: 'mock-uuid-789' };

jest.spyOn(passport, 'authenticate').mockImplementation(() => {
    return (req: any, res: any, next: any) => {
        req.user = dynamicUser; // Bramkarz zawsze bierze to, co aktualnie siedzi w dynamicUser
        next();
    };
});

import request from 'supertest';
import express from 'express';
import authRoute from '../src/backend/routes/authRoute';
import * as AuthService from '../src/backend/services/AuthService';

// Mockowanie AuthService
jest.mock('../src/backend/services/AuthService');

const app = express();
app.use(express.json());
app.use(passport.initialize());
app.use('/api/auth', authRoute);

describe('Google Auth Flow', () => {

    beforeEach(() => {
        jest.clearAllMocks();
        // Resetujemy usera do stanu domyślnego przed każdym testem
        dynamicUser = { id: 'google-12345', jwtSecureCode: 'mock-uuid-789' };
    });

    it('should handle successful callback and redirect to frontend with token', async () => {
        (AuthService.handleGoogleCallback as jest.Mock).mockReturnValue({
            authToken: 'fake-jwt-token-abcd'
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(302);
        expect(res.header.location).toContain('accessToken=fake-jwt-token-abcd');
    });

    it('should return 401 if passport fails to provide user data', async () => {
        // Ustawiamy "brak użytkownika" - teraz Twój if (!user) w routerze to wyłapie
        dynamicUser = undefined;

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(401);
        expect(res.body.message).toBe("Authentication failed");
    });

    it('should return 500 if AuthService fails', async () => {
        (AuthService.handleGoogleCallback as jest.Mock).mockImplementation(() => {
            throw new Error('Database down');
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(500);
        expect(res.body.message).toBe('An error occurred during authentication');
    });

    it('should handle missing FE_BASE_URL gracefully', async () => {
        const originalUrl = process.env.FE_BASE_URL;
        delete process.env.FE_BASE_URL;

        (AuthService.handleGoogleCallback as jest.Mock).mockReturnValue({ authToken: 'abc' });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.header.location).toContain('undefined?accessToken=abc');

        process.env.FE_BASE_URL = originalUrl;
    });
});