import jwt from 'jsonwebtoken';

interface GoogleCallbackParams {
    id: string;
}

export const getJwtTokens = async (params: GoogleCallbackParams) => {

    // 1. Przygotowanie danych do zaszycia w tokenie (Payload)
    const payload = {
        id: params.id,
    };
    const accessToken = jwt.sign(payload,process.env.JWT_ACCESS_SECRET,{expiresIn:process.env.JWT_ACCESS_EXPIRES_IN});

    const refreshToken = jwt.sign(payload,process.env.JWT_REFRESH_SECRET,{expiresIn: process.env.JWT_REFRESH_EXPIRES_IN});

    //await RefreshTokenModel.create({token:refreshToken,userId: params.id})
    return { accessToken,refreshToken };
};