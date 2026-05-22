import Card from './Card';
import { Card as CardModel } from '../models/Card';
import { CollectionEntry as CollectionEntryModel } from '../models/CollectionEntry';

const VALID_CONDITIONS = ['M', 'NM', 'GD', 'LP', 'MP', 'HP', 'DMG'] as const;
type CardCondition = typeof VALID_CONDITIONS[number];

export default class CollectionEntry {
    private id: string;
    private card: Card;
    private quantity: number;
    private condition: string;
    private isFoil: boolean;
    private notes: string | null;

    constructor(data: {
        id?: string;          // optional — not needed for pure in-memory/test usage
        card: Card;
        quantity: number;
        condition: string;
        isFoil?: boolean;     // optional — defaults to false
        notes: string | null;
    }) {
        this.id        = data.id       ?? '';
        this.card      = data.card;
        this.quantity  = data.quantity;
        this.condition = data.condition;
        this.isFoil    = data.isFoil   ?? false;
        this.notes     = data.notes;
    }

    static fromModel(model: InstanceType<typeof CollectionEntryModel>): CollectionEntry {
        const raw    = model.get() as Record<string, unknown>;
        const isFoil = raw.isFoil as boolean;
        const cardRaw = (model as any).Card as InstanceType<typeof CardModel> | undefined;
        const card   = cardRaw
            ? Card.fromModel(cardRaw, isFoil)
            : new Card({ id: raw.scryfallId as string });

        return new CollectionEntry({
            id:        raw.id        as string,
            card,
            quantity:  raw.quantity  as number,
            condition: raw.condition as string,
            isFoil,
            notes:     (raw.notes as string | null) ?? null,
        });
    }

    public getCard(): Card           { return this.card; }
    public getQuantity(): number     { return this.quantity; }
    public getCondition(): string    { return this.condition; }
    public getIsFoil(): boolean      { return this.isFoil; }
    public getNotes(): string | null { return this.notes; }

    // In-memory update is synchronous; DB write is fire-and-forget
    public updateQuantity(delta: number): void {
        const newQty = this.quantity + delta;
        if (newQty < 0) throw new Error('Quantity cannot go negative');
        this.quantity = newQty;
        if (!this.id) return;
        const op = newQty === 0
            ? CollectionEntryModel.destroy({ where: { id: this.id } })
            : CollectionEntryModel.update({ quantity: newQty }, { where: { id: this.id } });
        op.catch(err => console.error('updateQuantity DB error:', err));
    }

    public setCondition(condition: string): void {
        if (!condition || !(VALID_CONDITIONS as readonly string[]).includes(condition)) {
            throw new Error(`Invalid condition: ${condition}`);
        }
        this.condition = condition;
        if (this.id) {
            CollectionEntryModel.update({ condition }, { where: { id: this.id } })
                .catch(err => console.error('setCondition DB error:', err));
        }
    }

    public setNotes(notes: string | null): void {
        this.notes = notes;
        if (this.id) {
            CollectionEntryModel.update({ notes }, { where: { id: this.id } })
                .catch(err => console.error('setNotes DB error:', err));
        }
    }
}