import jwt from 'jsonwebtoken';

interface GoogleCallbackParams {
    id: string;
    jwtSecureCode: string;
}

export const handleGoogleCallback = (params: GoogleCallbackParams) => {
    // 1. Przygotowanie danych do zaszycia w tokenie (Payload)
    const payload = {
        sub: params.id,
        jsc: params.jwtSecureCode // to Twoje dodatkowe zabezpieczenie z UUID
    };

    // 2. Generowanie tokena JWT podpisanego Twoim kluczem z .env
    const authToken = jwt.sign(payload, process.env.JWT_SECRET || 'secret', {
        expiresIn: '7d', // token ważny np. 7 dni
    });

    // 3. Zwrócenie tokena do routera
    return { authToken };
};