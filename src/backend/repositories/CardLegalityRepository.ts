import { Op } from 'sequelize';
import type { CardLegalityRow, LegalityStatus } from '../deck/scryfallFormatMap';
import { CardLegality as CardLegalityModel } from '../models/CardLegality';
import type { DeckFormat } from './DeckRepository';

export const upsertCardLegalities = async (rows: CardLegalityRow[]): Promise<void> => {
    if (rows.length === 0) {
        return;
    }

    await CardLegalityModel.bulkCreate(
        rows.map((row) => ({
            scryfallId: row.scryfallId,
            format: row.format,
            status: row.status,
        })),
        { updateOnDuplicate: ['status'] },
    );
};

export const hasLegalities = async (scryfallId: string): Promise<boolean> => {
    const count = await CardLegalityModel.count({ where: { scryfallId } });
    return count > 0;
};

export const getLegalityStatus = async (
    scryfallId: string,
    format: DeckFormat,
): Promise<LegalityStatus | null> => {
    const row = await CardLegalityModel.findOne({
        where: { scryfallId, format },
    });
    if (!row) {
        return null;
    }
    return row.get('status') as LegalityStatus;
};

export const getLegalitiesForCards = async (
    scryfallIds: string[],
    format: DeckFormat,
): Promise<Map<string, LegalityStatus | null>> => {
    const result = new Map<string, LegalityStatus | null>();
    for (const scryfallId of scryfallIds) {
        result.set(scryfallId, null);
    }

    if (scryfallIds.length === 0) {
        return result;
    }

    const rows = await CardLegalityModel.findAll({
        where: {
            scryfallId: { [Op.in]: scryfallIds },
            format,
        },
    });

    for (const row of rows) {
        const raw = row.get() as { scryfallId: string; status: LegalityStatus };
        result.set(raw.scryfallId, raw.status);
    }

    return result;
};
