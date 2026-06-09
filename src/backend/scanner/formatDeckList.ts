import { type DeckBoard, type DeckFormat } from '../repositories/DeckRepository';

export interface DeckListCardInput {
    name: string;
    quantity: number;
    board: DeckBoard;
}

const aggregateKey = (name: string, board: DeckBoard): string =>
    `${board}\0${name.toLowerCase()}`;

const aggregateCards = (cards: DeckListCardInput[]): DeckListCardInput[] => {
    const aggregated = new Map<string, DeckListCardInput>();

    for (const card of cards) {
        const name = card.name.trim();
        if (name.length === 0 || card.quantity <= 0) {
            continue;
        }

        const key = aggregateKey(name, card.board);
        const existing = aggregated.get(key);
        if (existing) {
            existing.quantity += card.quantity;
        } else {
            aggregated.set(key, {
                name,
                quantity: card.quantity,
                board: card.board,
            });
        }
    }

    return Array.from(aggregated.values());
};

const sortByName = (cards: DeckListCardInput[]): DeckListCardInput[] =>
    [...cards].sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));

const formatCardLine = (card: DeckListCardInput): string =>
    `${card.quantity} ${card.name}`;

const commanderSectionHeader = (format: DeckFormat): string => {
    if (format === 'Oathbreaker') {
        return '// Oathbreaker & Signature';
    }
    return '// Commander';
};

const formatSection = (header: string, cards: DeckListCardInput[]): string[] => {
    if (cards.length === 0) {
        return [];
    }

    return [header, ...sortByName(cards).map(formatCardLine)];
};

export const formatDeckList = (
    cards: DeckListCardInput[],
    format: DeckFormat,
): string => {
    const aggregated = aggregateCards(cards);
    const main = aggregated.filter((c) => c.board === 'main');
    const sideboard = aggregated.filter((c) => c.board === 'sideboard');
    const commander = aggregated.filter((c) => c.board === 'commander');

    const sections: string[][] = [];

    if (main.length > 0) {
        sections.push(sortByName(main).map(formatCardLine));
    }

    const sideboardSection = formatSection('// Sideboard', sideboard);
    if (sideboardSection.length > 0) {
        sections.push(sideboardSection);
    }

    const commanderSection = formatSection(commanderSectionHeader(format), commander);
    if (commanderSection.length > 0) {
        sections.push(commanderSection);
    }

    return sections.map((lines) => lines.join('\n')).join('\n\n');
};
