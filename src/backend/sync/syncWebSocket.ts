import http from 'http';
import jwt from 'jsonwebtoken';
import { WebSocketServer, type WebSocket } from 'ws';
import * as SyncEventHub from '../services/SyncEventHub';

const WS_PATH = '/api/sync/stream';

type JwtPayload = { id: string };

const extractToken = (req: http.IncomingMessage): string | null => {
    const url = new URL(req.url ?? '/', 'http://localhost');
    const queryToken = url.searchParams.get('token');
    if (queryToken) return queryToken;

    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
        return authHeader.slice(7);
    }

    const cookie = req.headers.cookie;
    if (cookie) {
        const match = cookie.match(/(?:^|;\s*)accessToken=([^;]+)/);
        if (match?.[1]) return decodeURIComponent(match[1]);
    }

    return null;
};

const verifyUserId = (req: http.IncomingMessage): string | null => {
    const token = extractToken(req);
    if (!token) return null;

    try {
        const secret = process.env.JWT_ACCESS_SECRET || 'secret-test';
        const payload = jwt.verify(token, secret) as JwtPayload;
        return payload?.id ?? null;
    } catch {
        return null;
    }
};

export const attachSyncWebSocket = (server: http.Server): WebSocketServer => {
    const wss = new WebSocketServer({ server, path: WS_PATH });

    wss.on('connection', (socket: WebSocket, req) => {
        const userId = verifyUserId(req);
        if (!userId) {
            socket.close(4401, 'Unauthorized');
            return;
        }

        SyncEventHub.subscribe(userId, socket);

        socket.on('close', () => {
            SyncEventHub.unsubscribe(userId, socket);
        });

        socket.on('error', () => {
            SyncEventHub.unsubscribe(userId, socket);
        });
    });

    return wss;
};

export const SYNC_WS_PATH = WS_PATH;
