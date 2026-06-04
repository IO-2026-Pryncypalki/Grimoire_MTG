import type { FormatWarningDto } from './DeckFormatWarningService';
import type { DeckBoard, DeckFormat } from '../repositories/DeckRepository';
import type { DeckCardSummaryRecord } from '../repositories/DeckRepository';
import { normalizeCardName } from '../utils/cardNameMatch';

export interface DeckCardStatusInput {
    board: DeckBoard;
    quantity: number;
    scryfallId: string;
    name: string | null;
    typeLine: string | null;
    filledQty: number;
    formatWarning: FormatWarningDto | null;
}

export const toDeckCardStatusInput = (
    card: DeckCardSummaryRecord,
    formatWarning: FormatWarningDto | null,
): DeckCardStatusInput => ({
    board: card.board,
    quantity: card.quantity,
    scryfallId: card.scryfallId,
    name: card.name,
    typeLine: card.typeLine,
    filledQty: card.filledQty,
    formatWarning,
});

const checkCopyLimits = (
    cards: DeckCardStatusInput[],
    maxCopies: number,
): boolean => {
    const counts = new Map<string, number>();
    for (const card of cards) {
        counts.set(card.scryfallId, (counts.get(card.scryfallId) ?? 0) + card.quantity);
    }
    for (const total of counts.values()) {
        if (total > maxCopies) {
            return false;
        }
    }
    return true;
};

export const computeIsFormatValid = (
    format: DeckFormat,
    cards: DeckCardStatusInput[],
): boolean => {
    const mainCards = cards.filter((c) => c.board === 'main');
    const totalMain = mainCards.reduce((sum, c) => sum + c.quantity, 0);

    if (format === 'Standard' || format === 'Modern' || format === 'Pioneer') {
        if (totalMain < 60) {
            return false;
        }
        if (!checkCopyLimits(mainCards, 4)) {
            return false;
        }
    } else if (format === 'Commander') {
        if (totalMain < 100) {
            return false;
        }
        if (!checkCopyLimits(mainCards, 1)) {
            return false;
        }
    }

    const warningCount = cards.filter((c) => c.formatWarning !== null).length;
    if (warningCount > 0) {
        return false;
    }

    return true;
};

export const computeIsFullyAssigned = (
    cards: DeckCardStatusInput[],
    ownedNames: Set<string>,
): boolean => {
    const inCollection = cards.filter((card) => {
        if (!card.name) {
            return false;
        }
        return ownedNames.has(normalizeCardName(card.name));
    });

    if (inCollection.length === 0) {
        return false;
    }

    return inCollection.every((card) => card.filledQty >= card.quantity);
};

export const groupSummariesByDeckId = (
    summaries: DeckCardSummaryRecord[],
): Map<string, DeckCardSummaryRecord[]> => {
    const byDeck = new Map<string, DeckCardSummaryRecord[]>();
    for (const row of summaries) {
        const list = byDeck.get(row.deckId) ?? [];
        list.push(row);
        byDeck.set(row.deckId, list);
    }
    return byDeck;
};
