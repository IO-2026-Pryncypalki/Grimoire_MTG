import { Card as CardModel } from '../models/Card';

export default class Card {
    private scryfallId: string;
    private name: string | null;
    private setCode: string | null;
    private currentPrice: number | null;
    private imageUrl: string | null;

    constructor(data?: {
        scryfallId?: string;
        name?: string | null;
        setCode?: string | null;
        currentPrice?: number | null;
        imageUrl?: string | null;
    }) {
        this.scryfallId   = data?.scryfallId   ?? 'unknown-id';
        this.name         = data?.name         ?? null;
        this.setCode      = data?.setCode      ?? null;
        this.currentPrice = data?.currentPrice ?? null;
        this.imageUrl     = data?.imageUrl     ?? null;
    }

    static fromModel(model: InstanceType<typeof CardModel>, isFoil = false): Card {
        const raw = model.get() as Record<string, unknown>;
        return new Card({
            scryfallId:   raw.scryfallId as string,
            name:         raw.name       as string | null,
            setCode:      raw.setCode    as string | null,
            currentPrice: isFoil
                ? (raw.priceUsdFoil as number | null)
                : (raw.priceUsd    as number | null),
            imageUrl: raw.imageUri as string | null,
        });
    }

    public getScryfallId(): string          { return this.scryfallId; }
    public getName(): string | null         { return this.name; }
    public getSetCode(): string | null      { return this.setCode; }
    public getCurrentPrice(): number | null { return this.currentPrice; }
    public getImageUrl(): string | null     { return this.imageUrl; }

    // Used by Collection.refreshPrices() to update price in-memory
    public updatePrice(price: number | null): void {
        this.currentPrice = price;
    }
}