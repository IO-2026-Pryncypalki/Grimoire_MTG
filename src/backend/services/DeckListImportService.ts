import ScryfallScanResolver from '../scanner/ScryfallScanResolver';
import { parseDeckList } from '../scanner/parseDeckList';
import { ensureCardInDb } from './CardService';
import {
    addCardToDeckForUser,
    clearDeckCardsForUser,
    getByIdForUser,
    type DeckBoard,
} from '../repositories/DeckRepository';

export type ImportDeckListMode = 'merge' | 'replace';

export interface ImportDeckListInput {
    text: string;
    mode: ImportDeckListMode;
}

export interface ImportedDeckListItem {
    name: string;
    scryfallId: string;
    quantity: number;
    board: DeckBoard;
}

export type ImportDeckListFailureReason = 'not_found' | 'rate_limit';

export interface ImportDeckListFailure {
    line?: number;
    name: string;
    reason: ImportDeckListFailureReason;
}

export interface ImportDeckListResult {
    mode: ImportDeckListMode;
    imported: ImportedDeckListItem[];
    failed: ImportDeckListFailure[];
    clearedExisting: boolean;
}

export const importDeckFromList = async (
    userId: string,
    deckId: string,
    input: ImportDeckListInput,
    resolver: ScryfallScanResolver,
): Promise<ImportDeckListResult> => {
    const deck = await getByIdForUser(deckId, userId);
    if (!deck) {
        throw new Error('Deck not found');
    }

    const entries = parseDeckList(input.text);
    const imported: ImportedDeckListItem[] = [];
    const failed: ImportDeckListFailure[] = [];
    let clearedExisting = false;

    if (input.mode === 'replace') {
        const cleared = await clearDeckCardsForUser(deckId, userId);
        if (!cleared) {
            throw new Error('Deck not found');
        }
        clearedExisting = true;
    }

    for (const entry of entries) {
        const resolution = await resolver.resolveByName(entry.name);

        if (resolution.kind === 'rate_limit') {
            failed.push({
                line: entry.line,
                name: entry.name,
                reason: 'rate_limit',
            });
            continue;
        }

        if (resolution.kind === 'not_found' || resolution.kind === 'ambiguous') {
            failed.push({
                line: entry.line,
                name: entry.name,
                reason: 'not_found',
            });
            continue;
        }

        const scryfallId = resolution.card.getScryfallId();
        await ensureCardInDb(scryfallId);

        await addCardToDeckForUser(deckId, userId, {
            scryfallId,
            quantity: entry.quantity,
            board: entry.board,
        });

        imported.push({
            name: entry.name,
            scryfallId,
            quantity: entry.quantity,
            board: entry.board,
        });
    }

    return {
        mode: input.mode,
        imported,
        failed,
        clearedExisting,
    };
};
