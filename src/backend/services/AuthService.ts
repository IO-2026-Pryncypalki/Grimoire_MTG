import jwt from 'jsonwebtoken';

interface GoogleCallbackParams {
    id: string;
    jwtSecureCode: string;
}

export const handleGoogleCallback = async (params: GoogleCallbackParams) => {

    // 1. Przygotowanie danych do zaszycia w tokenie (Payload)
    const payload = {
        sub: params.id,
        jsc: params.jwtSecureCode // to Twoje dodatkowe zabezpieczenie z UUID
    };
    const accessToken = jwt.sign(payload,process.env.JWT_ACCESS_SECRET,{expiresIn:'15m'});

    const refreshToken = jwt.sign(payload,process.env.JWT_REFRESH_SECRET,{expiresIn: '14d'});

    //await RefreshTokenModel.create({token:refreshToken,userId: params.id})
    return { accessToken,refreshToken };
};