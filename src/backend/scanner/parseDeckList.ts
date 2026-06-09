import { type DeckBoard } from '../repositories/DeckRepository';

export interface ParsedDeckListEntry {
    name: string;
    quantity: number;
    board: DeckBoard;
    line: number;
}

const CARD_LINE_RE = /^(\d+)x?\s+(.+)$/i;
const SECTION_COMMENT_RE = /^\/\/\s*(.+)$/i;

type SectionKind = 'main' | 'commander' | 'sideboard' | 'oathbreaker';

const detectSection = (comment: string): SectionKind | null => {
    const lower = comment.toLowerCase();

    if (lower.includes('oathbreaker')) {
        return 'oathbreaker';
    }
    if (lower.includes('sideboard')) {
        return 'sideboard';
    }
    if (lower.includes('commander')) {
        return 'commander';
    }
    if (
        lower.includes('maindeck') ||
        lower.includes('main deck') ||
        lower === 'main' ||
        lower.includes('main board') ||
        lower === 'deck'
    ) {
        return 'main';
    }

    return null;
};

const aggregateKey = (name: string, board: DeckBoard): string =>
    `${board}\0${name.toLowerCase()}`;

export const parseDeckList = (text: string): ParsedDeckListEntry[] => {
    const lines = text.split(/\r?\n/);
    const aggregated = new Map<string, ParsedDeckListEntry>();

    let currentBoard: DeckBoard = 'main';
    let oathbreakerSection = false;
    let oathbreakerCardIndex = 0;

    for (let i = 0; i < lines.length; i += 1) {
        const rawLine = lines[i];
        const lineNumber = i + 1;
        const trimmed = rawLine.trim();

        if (trimmed.length === 0 || trimmed.startsWith('#')) {
            continue;
        }

        const sectionMatch = trimmed.match(SECTION_COMMENT_RE);
        if (sectionMatch) {
            const section = detectSection(sectionMatch[1]);
            if (section === 'oathbreaker') {
                oathbreakerSection = true;
                oathbreakerCardIndex = 0;
                currentBoard = 'commander';
            } else if (section === 'commander') {
                oathbreakerSection = false;
                currentBoard = 'commander';
            } else if (section === 'sideboard') {
                oathbreakerSection = false;
                currentBoard = 'sideboard';
            } else if (section === 'main') {
                oathbreakerSection = false;
                currentBoard = 'main';
            }
            continue;
        }

        const cardMatch = trimmed.match(CARD_LINE_RE);
        if (!cardMatch) {
            continue;
        }

        const quantity = Number.parseInt(cardMatch[1], 10);
        const name = cardMatch[2].trim();
        if (quantity <= 0 || name.length === 0) {
            continue;
        }

        let board: DeckBoard = currentBoard;
        if (oathbreakerSection) {
            board = oathbreakerCardIndex === 0 ? 'commander' : 'main';
            oathbreakerCardIndex += 1;
        }

        const key = aggregateKey(name, board);
        const existing = aggregated.get(key);
        if (existing) {
            existing.quantity += quantity;
        } else {
            aggregated.set(key, {
                name,
                quantity,
                board,
                line: lineNumber,
            });
        }
    }

    return Array.from(aggregated.values());
};
