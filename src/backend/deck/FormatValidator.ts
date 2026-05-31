import Deck from './Deck';
import Card from '../collection/Card';
import Rules from '../interfaces/Rules';
import type { DeckFormat } from '../repositories/DeckRepository';
import { shouldCheckFormatLegality } from './scryfallFormatMap';
import type { LegalityStatus } from './scryfallFormatMap';

export type { LegalityStatus };

export interface FormatWarning {
    status: Exclude<LegalityStatus, 'legal'>;
    message: string;
}

const STANDARD_RULES: Rules = {
    minCards: 60,
    maxCopies: (isBasicLand) => (isBasicLand ? Number.MAX_SAFE_INTEGER : 4),
};

const COMMANDER_RULES: Rules = {
    minCards: 100,
    maxCards: 100,
    maxCopies: (isBasicLand) => (isBasicLand ? Number.MAX_SAFE_INTEGER : 1),
};

const FORMAT_RULES = new Map<string, Rules>([
    ['Standard', STANDARD_RULES],
    ['Commander', COMMANDER_RULES],
]);

const isBasicLand = (card: Card): boolean => {
    const typeLine = card.getTypeLine();
    return typeLine !== null && typeLine.includes('Basic Land');
};

export default class FormatValidator {
    private formatRules: Map<string, Rules> = new Map(FORMAT_RULES);

    public getCardFormatWarning(
        status: LegalityStatus | null | undefined,
        deckFormat: DeckFormat,
    ): FormatWarning | null {
        if (!shouldCheckFormatLegality(deckFormat) || !status || status === 'legal') {
            return null;
        }

        const messages: Record<Exclude<LegalityStatus, 'legal'>, string> = {
            not_legal: `Karta nie jest legalna w formacie ${deckFormat}`,
            restricted: `Karta jest restricted w formacie ${deckFormat}`,
            banned: `Karta jest banned w formacie ${deckFormat}`,
        };

        return {
            status,
            message: messages[status],
        };
    }

    public isValid(deck: Deck | null, format: string): boolean {
        if (!deck) {
            throw new Error('Deck must not be null');
        }

        const rules = this.loadRules(format);
        const entries = deck.getCards();
        const totalCards = entries.reduce((sum, entry) => sum + entry.getQuantity(), 0);

        if (totalCards < rules.minCards) {
            return false;
        }
        if (rules.maxCards !== undefined && totalCards > rules.maxCards) {
            return false;
        }

        for (const entry of entries) {
            const card = entry.getCard();
            const maxCopies = rules.maxCopies(isBasicLand(card));
            if (entry.getQuantity() > maxCopies) {
                return false;
            }
        }

        return true;
    }

    private loadRules(format: string): Rules {
        const rules = this.formatRules.get(format);
        if (!rules) {
            throw new Error(`Unknown format: ${format}`);
        }
        return rules;
    }
}
