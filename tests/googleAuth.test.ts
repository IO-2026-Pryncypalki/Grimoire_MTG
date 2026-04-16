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
jest.mock('../src/backend/models/Session', () => ({
    Session: {
        create: jest.fn().mockResolvedValue({}), // Udajemy, że zapis do bazy zawsze działa
    }
}));
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
        (AuthService.getJwtTokens as jest.Mock).mockResolvedValue({
            accessToken: 'fake-access-token-123',
            refreshToken: 'fake-refresh-token-456'
        });

        const res = await request(app).get('/api/auth/google/callback');

        // 2. Status dalej powinien być 302 (Redirect)
        expect(res.status).toBe(302);

        // 3. Sprawdzamy przekierowanie - teraz powinno iść na czysty URL frontendu
        // Bez żadnych znaków zapytania i tokenów
        expect(res.header.location).toBe(process.env.BE_BASE_URL+'/api/user');

        // 4. KLUCZOWY MOMENT: Sprawdzamy ciasteczka
        const cookies = res.header['set-cookie'];
        expect(cookies).toBeDefined();

        // Sprawdzamy czy accessToken jest w ciasteczkach
        const hasAccessToken = cookies.some((c: string) => c.includes('accessToken=fake-access-token-123'));
        // Sprawdzamy czy refreshToken jest w ciasteczkach
        const hasRefreshToken = cookies.some((c: string) => c.includes('refreshToken=fake-refresh-token-456'));

        expect(hasAccessToken).toBe(true);
        expect(hasRefreshToken).toBe(true);
    });

    it('should return 401 if passport fails to provide user data', async () => {
        // Ustawiamy "brak użytkownika" - teraz Twój if (!user) w routerze to wyłapie
        dynamicUser = undefined;

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(401);
        expect(res.body.message).toBe("Authentication failed");
    });

    it('should return 500 if AuthService fails', async () => {
        (AuthService.getJwtTokens as jest.Mock).mockImplementation(() => {
            throw new Error('Database down');
        });

        const res = await request(app).get('/api/auth/google/callback');

        expect(res.status).toBe(500);
        expect(res.body.message).toBe('An error occurred during authentication');
    });

    it('should handle missing FE_BASE_URL by falling back to a default route', async () => {
        // 1. Symulujemy brak URL-a frontendu
        const originalUrl = process.env.FE_BASE_URL;
        process.env.FE_BASE_URL = '';

        // 2. Mockujemy AuthService tak, żeby zwracał TO, czego kod teraz oczekuje
        (AuthService.getJwtTokens as jest.Mock).mockResolvedValue({
            accessToken: 'abc',
            refreshToken: 'szubidubi'
        });

        const res = await request(app).get('/api/auth/google/callback');

        // 3. Sprawdzamy, gdzie nas wywiało.
        // Jeśli w kodzie masz fallback (np. res.redirect(process.env.FE_BASE_URL || '/')), to testuj '/'
        expect(res.status).toBe(302);
        expect(res.header.location).toBeDefined();
        // Nie szukamy już "?accessToken=abc" w URL!
        expect(res.header.location).not.toContain('accessToken=');

        // 4. Sprawdzamy czy mimo braku URL-a, ciastka i tak zostały ustawione
        const cookies = res.header['set-cookie'];
        expect(cookies).toBeDefined();
        expect(cookies.some((c: string) => c.includes('accessToken=abc'))).toBe(true);

        process.env.FE_BASE_URL = originalUrl;
    });
});