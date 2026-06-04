import type { WebSocket } from 'ws';
import { getSyncStatusForUser } from './SyncService';

export interface SyncPushMessage {
    type: 'sync';
    collectionUpdatedAt: string;
    decksUpdatedAt: string;
    syncToken: string;
}

const clientsByUser = new Map<string, Set<WebSocket>>();

export const subscribe = (userId: string, socket: WebSocket): void => {
    let set = clientsByUser.get(userId);
    if (!set) {
        set = new Set();
        clientsByUser.set(userId, set);
    }
    set.add(socket);
};

export const unsubscribe = (userId: string, socket: WebSocket): void => {
    const set = clientsByUser.get(userId);
    if (!set) return;
    set.delete(socket);
    if (set.size === 0) {
        clientsByUser.delete(userId);
    }
};

export const publish = async (userId: string): Promise<void> => {
    const set = clientsByUser.get(userId);
    if (!set || set.size === 0) return;

    const status = await getSyncStatusForUser(userId);
    const payload: SyncPushMessage = {
        type: 'sync',
        collectionUpdatedAt: status.collectionUpdatedAt,
        decksUpdatedAt: status.decksUpdatedAt,
        syncToken: status.syncToken,
    };
    const data = JSON.stringify(payload);

    for (const socket of set) {
        if (socket.readyState === socket.OPEN) {
            socket.send(data);
        }
    }
};

export const startHeartbeat = (): NodeJS.Timeout => {
    return setInterval(() => {
        for (const [, sockets] of clientsByUser) {
            for (const socket of sockets) {
                if (socket.readyState === socket.OPEN) {
                    socket.ping();
                }
            }
        }
    }, 30_000);
};
