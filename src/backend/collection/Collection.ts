import Card from './Card';
import CollectionEntry from './CollectionEntry';
import ICardProvider from '../interfaces/ICardProvider';
import { Card as CardModel } from '../models/Card';
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';

export default class Collection {
    private userId: string;
    private entries: CollectionEntry[] = [];

    constructor(data: { userId: string; entries?: CollectionEntry[] }) {
        this.userId  = data.userId;
        if (data.entries) this.entries = data.entries;
    }

    static async load(userId: string): Promise<Collection> {
        const rows    = await CollectionEntryModel.findAll({
            where:   { userId },
            include: [{ model: CardModel }],
        });
        const entries = rows.map(row => CollectionEntry.fromModel(row));
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
            this.entries.push(new CollectionEntry({ card, quantity, condition, isFoil, notes: null }));
            CollectionEntryModel.findOrCreate({
                where:    { userId: this.userId, scryfallId: card.getScryfallId(), condition, isFoil },
                defaults: { quantity },
            }).catch(err => console.error('addCard DB error:', err));
        }
    }

    // Synchronous in-memory update; DB delete is fire-and-forget
    public removeCard(scryfallId: string): void {
        this.entries = this.entries.filter(
            e => e.getCard().getScryfallId() !== scryfallId
        );
        CollectionEntryModel.destroy({ where: { userId: this.userId, scryfallId } })
            .catch(err => console.error('removeCard DB error:', err));
    }

    // Returns null for missing entries instead of throwing — matches test expectations
    public getEntry(scryfallId: string): CollectionEntry | null {
        return this.entries.find(e => e.getCard().getScryfallId() === scryfallId) ?? null;
    }

    public getEntries(): CollectionEntry[] { return this.entries; }

    public calculateTotalValue(): number {
        return this.entries.reduce((sum, entry) => {
            const price = entry.getCard().getCurrentPrice() ?? 0;
            return sum + price * entry.getQuantity();
        }, 0);
    }

    // Async — callers must await. Continues on per-card errors (resilient).
    public async refreshPrices(provider: ICardProvider): Promise<void> {
        for (const entry of this.entries) {
            try {
                const scryfallId = entry.getCard().getScryfallId();
                const newPrice   = await provider.getPrice(scryfallId);
                entry.getCard().updatePrice(newPrice);
                CardModel.update(
                    { priceUsd: newPrice, pricesUpdatedAt: new Date() },
                    { where: { scryfallId } }
                ).catch(err => console.error('refreshPrices DB error:', err));
            } catch {
                // One card failing doesn't stop the rest
            }
        }
    }
}