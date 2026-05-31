import FormatValidator, { type FormatWarning } from '../deck/FormatValidator';
import type { DeckFormat } from '../repositories/DeckRepository';
import { getLegalitiesForCards, getLegalityStatus } from '../repositories/CardLegalityRepository';
import { ensureLegalitiesInDb } from './CardService';

const validator = new FormatValidator();

export type FormatWarningDto = FormatWarning;

const toWarningDto = (
    status: Parameters<FormatValidator['getCardFormatWarning']>[0],
    deckFormat: DeckFormat,
): FormatWarningDto | null => validator.getCardFormatWarning(status, deckFormat);

export const getWarningForCard = async (
    scryfallId: string,
    deckFormat: DeckFormat,
): Promise<FormatWarningDto | null> => {
    await ensureLegalitiesInDb(scryfallId);
    const status = await getLegalityStatus(scryfallId, deckFormat);
    return toWarningDto(status, deckFormat);
};

export const getWarningsForDeckCards = async (
    scryfallIds: string[],
    deckFormat: DeckFormat,
): Promise<Map<string, FormatWarningDto | null>> => {
    const warnings = new Map<string, FormatWarningDto | null>();
    for (const scryfallId of scryfallIds) {
        warnings.set(scryfallId, null);
    }

    if (scryfallIds.length === 0) {
        return warnings;
    }

    await Promise.all(scryfallIds.map((scryfallId) => ensureLegalitiesInDb(scryfallId)));
    const statuses = await getLegalitiesForCards(scryfallIds, deckFormat);

    for (const [scryfallId, status] of statuses) {
        warnings.set(scryfallId, toWarningDto(status, deckFormat));
    }

    return warnings;
};
