import type { DeckFormat } from '../repositories/DeckRepository';

export type LegalityStatus = 'legal' | 'not_legal' | 'restricted' | 'banned';

export interface CardLegalityRow {
    scryfallId: string;
    format: DeckFormat;
    status: LegalityStatus;
}

export const SCRYFALL_FORMAT_KEYS: Partial<Record<DeckFormat, string>> = {
    Standard: 'standard',
    Pioneer: 'pioneer',
    Modern: 'modern',
    Legacy: 'legacy',
    Vintage: 'vintage',
    Commander: 'commander',
    Pauper: 'pauper',
    Oathbreaker: 'oathbreaker',
};

const LEGALITY_STATUSES = new Set<LegalityStatus>([
    'legal',
    'not_legal',
    'restricted',
    'banned',
]);

export const isLegalityStatus = (value: string): value is LegalityStatus =>
    LEGALITY_STATUSES.has(value as LegalityStatus);

export const shouldCheckFormatLegality = (format: DeckFormat): boolean =>
    format in SCRYFALL_FORMAT_KEYS;

export const extractLegalitiesRows = (
    scryfallId: string,
    legalities: Record<string, string> | null | undefined,
): CardLegalityRow[] => {
    if (!legalities) {
        return [];
    }

    const rows: CardLegalityRow[] = [];
    for (const [deckFormat, scryfallKey] of Object.entries(SCRYFALL_FORMAT_KEYS)) {
        const raw = legalities[scryfallKey];
        if (raw && isLegalityStatus(raw)) {
            rows.push({
                scryfallId,
                format: deckFormat as DeckFormat,
                status: raw,
            });
        }
    }
    return rows;
};
