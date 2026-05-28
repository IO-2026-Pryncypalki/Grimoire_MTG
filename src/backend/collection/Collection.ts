import Card from './Card';
import CollectionEntry from './CollectionEntry';
import ICardProvider from '../interfaces/ICardProvider';
import { Card as CardModel } from '../models/Card'; // To jest Twoja nowa klasa
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry'; // To jest Twoja nowa klasa
import { Op } from 'sequelize';

export interface CollectionFilters {
    color?: string;
    type?: string;
    cmc?: number;
    edition?: string;
}

export interface RefreshPricesResult {
    totalCards: number;
    updatedCards: number;
    failedCards: number;
    failedIds: string[];
}

type PriceProvider = Pick<ICardProvider, 'getPrice'>;

export default class Collection {
    private userId: string;
    private entries: CollectionEntry[] = [];

    constructor(data: { userId: string; entries?: CollectionEntry[] }) {
        this.userId = data.userId;
        if (data.entries) this.entries = data.entries;
    }

    static async load(userId: string, filters: CollectionFilters = {}): Promise<Collection> {
        const cardWhere: any = {};

        if (filters.color) {
            cardWhere.colors = { [Op.contains]: [filters.color] };
        }
        if (filters.type) {
            cardWhere.typeLine = { [Op.iLike]: `%${filters.type}%` };
        }
        if (filters.cmc !== undefined) {
            cardWhere.cmc = filters.cmc;
        }
        if (filters.edition) {
            cardWhere[Op.or] = [
                { setCode: { [Op.iLike]: filters.edition } },
                { setName: { [Op.iLike]: `%${filters.edition}%` } },
            ];
        }

        const include = Reflect.ownKeys(cardWhere).length > 0
            ? [{ model: CardModel, where: cardWhere }]
            : [{ model: CardModel }];

        const rows = await CollectionEntryModel.findAll({
            where: { userId },
            include,
        });

        // rzutowanie na 'any' na wypadek gdyby fromModel kumpla oczekiwał starego schematu
        const entries = rows.map((row: any) => CollectionEntry.fromModel(row));
        return new Collection({ userId, entries });
    }

    // Synchronous in-memory update; DB upsert is fire-and-forget
    public addCard(card: Card | null, options: { quantity?: number; condition?: string; isFoil?: boolean } = {}): void {
        if (!card) throw new Error("You can't add null");
        const { quantity = 1, condition = 'NM', isFoil = false } = options;

        const existing = this.entries.find(e =>
            e.getCard().getScryfallId() === card.getScryfallId() &&
            e.getCondition() === condition &&
            e.getIsFoil() === isFoil
        );

        if (existing) {
            existing.updateQuantity(quantity);
        } else {
            // Ponieważ Twoje modele zmieniły CardCondition na union type ('NM' | 'M' | itd), rzutujemy
            this.entries.push(new CollectionEntry({ card, quantity, condition: condition as any, isFoil, notes: null }));
            CollectionEntryModel.findOrCreate({
                where: { userId: this.userId, scryfallId: card.getScryfallId(), condition: condition as any, isFoil },
                defaults: { quantity },
            }).catch((err: any) => console.error('addCard DB error:', err));
        }
    }

    // Moves `quantity` copies from one condition to another.
    public transferCondition(
        scryfallId: string,
        fromCondition: string,
        toCondition: string,
        isFoil: boolean,
        quantity: number = 1
    ): void {
        const fromEntry = this.getEntry(scryfallId, fromCondition, isFoil);
        if (!fromEntry) throw new Error('Source entry not found');
        if (fromEntry.getQuantity() < quantity) throw new Error('Not enough cards in that condition');

        fromEntry.updateQuantity(-quantity);

        const toEntry = this.getEntry(scryfallId, toCondition, isFoil);
        if (toEntry) {
            toEntry.updateQuantity(quantity);
        } else {
            this.addCard(fromEntry.getCard(), { quantity, condition: toCondition, isFoil });
        }

        this.pruneEmpty();
    }

    public getEntry(scryfallId: string, condition?: string, isFoil?: boolean): CollectionEntry | null {
        return this.entries.find(e =>
            e.getCard().getScryfallId() === scryfallId &&
            (condition === undefined || e.getCondition() === condition) &&
            (isFoil === undefined || e.getIsFoil() === isFoil)
        ) ?? null;
    }

    public removeCard(scryfallId: string, condition?: string, isFoil?: boolean): void {
        this.entries = this.entries.filter(e =>
            !(e.getCard().getScryfallId() === scryfallId &&
                (condition === undefined || e.getCondition() === condition) &&
                (isFoil === undefined || e.getIsFoil() === isFoil))
        );
        const where: any = { userId: this.userId, scryfallId };
        if (condition !== undefined) where.condition = condition;
        if (isFoil !== undefined) where.isFoil = isFoil;

        CollectionEntryModel.destroy({ where })
            .catch((err: any) => console.error('removeCard DB error:', err));
    }

    public getEntries(): CollectionEntry[] { return this.entries; }

    public calculateTotalValue(): number {
        return this.entries.reduce((sum, entry) => {
            const price = entry.getCard().getCurrentPrice() ?? 0;
            return sum + price * entry.getQuantity();
        }, 0);
    }

    public async refreshPrices(provider: PriceProvider): Promise<RefreshPricesResult> {
        const result: RefreshPricesResult = {
            totalCards: this.entries.length,
            updatedCards: 0,
            failedCards: 0,
            failedIds: [],
        };

        for (const entry of this.entries) {
            const scryfallId = entry.getCard().getScryfallId();
            try {
                const newPrice = await provider.getPrice(scryfallId, entry.getIsFoil());

                if (newPrice === null) {
                    result.failedCards += 1;
                    result.failedIds.push(scryfallId);
                    continue;
                }

                const priceField = entry.getIsFoil() ? 'priceUsdFoil' : 'priceUsd';
                await CardModel.update(
                    { [priceField]: newPrice, pricesUpdatedAt: new Date() },
                    { where: { scryfallId } }
                );

                entry.getCard().updatePrice(newPrice);
                result.updatedCards += 1;
            } catch {
                result.failedCards += 1;
                result.failedIds.push(scryfallId);
            }
        }

        return result;
    }

    public pruneEmpty(): void {
        this.entries = this.entries.filter(e => e.getQuantity() > 0);
    }
}