import dotenv from 'dotenv';
dotenv.config();
import express, { Request, Response } from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import sequelize from './config/database';
import passport from './auth/passport';
import authRoute from './routes/authRoute';
import userRoute from './routes/userRoute';
import cardRoute from './routes/cardRoute';
import collectionRoute from './routes/collectionRoute';
import deckRoute from './routes/deckRoute';
import syncRoute from './routes/syncRoute';
import './models/associations';

const app = express();

const allowedOrigins = [
    process.env.FE_BASE_URL,
    process.env.MOBILE_REDIRECT_URL?.split('?')[0],
]
    .filter((origin): origin is string => typeof origin === 'string' && origin.length > 0);

app.use(
    cors({
        origin: (origin, callback) => {
            if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
                callback(null, true);
            } else {
                callback(null, true);
            }
        },
        credentials: true,
    }),
);

app.use(express.json());
app.use(cookieParser());
app.use(passport.initialize());
app.use('/api/auth', authRoute);
app.use('/api/user', userRoute);
app.use('/api/cards', cardRoute);
app.use('/api/collection', collectionRoute);
app.use('/api/decks', deckRoute);
app.use('/api/sync', syncRoute);

app.get('/', (req: Request, res: Response) => {
    res.send('welcome to the Google OAuth 2.0 + JWT Node.js app!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`server is running on http://localhost:${PORT}`);
});
