import { Card as CardModel } from '../models/Card';
export interface Price {
    usd: number
    usd_foil: number
    eur: number
    eur_foil: number
}
export default class Card {
    private scryfallId: string;
    private name: string | null;
    private setCode: string | null;
    private setName: string | null;
    private collectorNumber: string | null;
    private lang: string | null;
    private manaCost: string | null;
    private cmc: number | null;
    private typeLine: string | null;
    private oracleText: string | null;
    private power: string | null;
    private toughness: string | null;
    private rarity: string | null;
    private colors: string[] = []
    private colorsIdentity: string[] = []
    private imageUri: any | null;
    private priceUsd: number | null;
    private priceUsdFoil: number | null;
    private priceEur: number | null;
    private priceEurFoil: number | null;
    private scryfallUri: string | null;

    constructor(data?: {
        id?: string,
        name?: string | null,
        set?: string | null,
        set_name?: string | null,
        collector_number?: string | null,
        lang?: string | null,
        mana_cost?: string | null,
        cmc?: number | null,
        type_line?: string | null,
        oracle_id?: string | null,
        power?: string | null,
        toughness?: string | null,
        rarity?: string | null,
        colors?: string[],
        colors_identity?: string[],
        image_uris?: any | null,
        prices?: Price | null,
        scryfall_uri?: string | null,
    }) {
        this.scryfallId = data?.id ?? "unknown-id";
        this.name = data?.name ?? null;
        this.setCode = data?.set ?? null;
        this.setName = data?.set_name ?? null;
        this.collectorNumber = data?.collector_number ?? null,
            this.lang = data?.lang ?? null,
            this.manaCost = data?.mana_cost ?? null,
            this.cmc = data?.cmc ?? null,
            this.typeLine = data?.type_line ?? null,
            this.oracleText = data?.oracle_id ?? null,
            this.power = data?.power ?? null,
            this.toughness = data?.toughness ?? null,
            this.rarity = data?.rarity ?? null;
        if (data?.colors) this.colors = data?.colors;
        if (data?.colors_identity) this.colorsIdentity = data?.colors_identity;
        this.imageUri = data?.image_uris?.normal ?? null;
        this.priceUsd = data?.prices?.usd ?? null;
        this.priceUsdFoil = data?.prices?.usd_foil ?? null;
        this.priceEur = data?.prices?.eur ?? null;
        this.priceEurFoil = data?.prices?.eur_foil ?? null;
        this.scryfallUri = data?.scryfall_uri ?? null;
    }
    public getScryfallId(): string {
        return this.scryfallId
    }
    public getName(): string | null {
        return this.name;
    }
    public getSetCode(): string | null {
        return this.setCode;
    }
    // public getCurrentPrice(): Price | null{
    //     return this.currentPrice;
    // }
    public getImageUrl(): string | null {
        return this.imageUri;
    }
    public getCurrentPrice(): number | null {
        return this.priceUsd;
    }

    public updatePrice(price: number | null): void {
        this.priceUsd = price;
    }

    // Constructs a Card domain object from a Sequelize model instance
    static fromModel(model: InstanceType<typeof CardModel>, isFoil = false): Card {
        const instance = new Card();

        // Zamiast uzywac .get(), po prostu odwolujemy sie do pol (TypeScript teraz je widzi!)
        instance.scryfallId = model.scryfallId;
        instance.name = model.name;
        instance.setCode = model.setCode;
        instance.setName = model.setName;
        instance.collectorNumber = model.collectorNumber;
        instance.imageUri = model.imageUri ?? null;

        // Ceny i logika foila
        instance.priceUsd = isFoil
            ? (model.priceUsdFoil ?? null)
            : (model.priceUsd ?? null);

        instance.priceUsdFoil = model.priceUsdFoil ?? null;
        instance.priceEur = model.priceEur ?? null;
        instance.priceEurFoil = model.priceEurFoil ?? null;
        instance.scryfallUri = model.scryfallUri ?? null;

        return instance;
    }
}
