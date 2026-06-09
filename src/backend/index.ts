import dotenv from 'dotenv';
dotenv.config();
import http from 'http';
import express, { Request, Response } from 'express';
import cookieParser from 'cookie-parser';
import cors from 'cors';
import passport from './auth/passport';
import authRoute from './routes/authRoute';
import userRoute from './routes/userRoute';
import { createCardRoute } from './routes/cardRoute';
import collectionRoute from './routes/collectionRoute';
import { createDeckRoute } from './routes/deckRoute';
import syncRoute from './routes/syncRoute';
import './models/associations';
import { attachSyncWebSocket } from './sync/syncWebSocket';
import { startHeartbeat } from './services/SyncEventHub';
import ScannerService from './scanner/ScannerService';
import ScryfallScanResolver, { BASE_DELAY_MS } from './scanner/ScryfallScanResolver';
import { buildFromScryfall } from './scanner/symspell';
import { SymbologyCache } from './scanner/symbologyCache';
import { createSymbologyRoute } from './routes/symbologyRoute';

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
app.use('/api/collection', collectionRoute);
app.use('/api/sync', syncRoute);

app.get('/', (req: Request, res: Response) => {
    res.send('welcome to the Google OAuth 2.0 + JWT Node.js app!');
});

const PORT = process.env.PORT || 3000;
const server = http.createServer(app);

attachSyncWebSocket(server);
startHeartbeat();

async function main(): Promise<void> {
    let symspell;
    try {
        symspell = await buildFromScryfall();
        console.log('SymSpell card-name index loaded');
    } catch (error) {
        console.error('SymSpell index failed; scanner falls back to exact→fuzzy:', error);
    }

    const symbology = new SymbologyCache();
    try {
        await symbology.loadFromScryfall();
    } catch (error) {
        console.error('Symbology load failed; symbol images unavailable:', error);
    }
    app.use('/api/symbology', createSymbologyRoute(symbology));

    const scannerService = new ScannerService({
        resolver: new ScryfallScanResolver(BASE_DELAY_MS, symspell),
    });
    const scanResolver = new ScryfallScanResolver(BASE_DELAY_MS, symspell);
    app.use('/api/cards', createCardRoute(scannerService));
    app.use('/api/decks', createDeckRoute(scanResolver));

    server.listen(PORT, () => {
        console.log(`server is running on http://localhost:${PORT}`);
    });
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
