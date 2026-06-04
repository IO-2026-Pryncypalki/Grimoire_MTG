import { Card as CardModel } from '../models/Card';
import { scryfallHiResFromStoredNormal } from '../scanner/scryfallImageUrl';
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
    private imageUriLarge: string | null = null;
    private imageUriPng: string | null = null;
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
        oracle_text?: string | null,
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
            this.oracleText = data?.oracle_text ?? data?.oracle_id ?? null,
            this.power = data?.power ?? null,
            this.toughness = data?.toughness ?? null,
            this.rarity = data?.rarity ?? null;
        if (data?.colors) this.colors = data?.colors;
        if (data?.colors_identity) this.colorsIdentity = data?.colors_identity;
        this.imageUri = data?.image_uris?.normal ?? null;
        this.imageUriLarge =
            data?.image_uris?.large
            ?? scryfallHiResFromStoredNormal(this.imageUri, 'grid');
        this.imageUriPng =
            data?.image_uris?.png
            ?? scryfallHiResFromStoredNormal(this.imageUri, 'detail');
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
    public getSetName(): string | null {
        return this.setName;
    }
    public getCollectorNumber(): string | null {
        return this.collectorNumber;
    }
    public getLang(): string | null {
        return this.lang;
    }
    public getManaCost(): string | null {
        return this.manaCost;
    }
    public getCmc(): number | null {
        return this.cmc;
    }
    public getTypeLine(): string | null {
        return this.typeLine;
    }
    public getOracleText(): string | null {
        return this.oracleText;
    }
    public getPower(): string | null {
        return this.power;
    }
    public getToughness(): string | null {
        return this.toughness;
    }
    public getRarity(): string | null {
        return this.rarity;
    }
    public getColors(): string[] {
        return this.colors;
    }
    public getColorIdentity(): string[] {
        return this.colorsIdentity;
    }
    public getImageUrl(): string | null {
        return this.imageUri;
    }
    public getImageUrlHiRes(variant: 'grid' | 'detail' = 'grid'): string | null {
        if (variant === 'detail') {
            return this.imageUriPng
                ?? this.imageUriLarge
                ?? scryfallHiResFromStoredNormal(this.imageUri, 'detail')
                ?? scryfallHiResFromStoredNormal(this.imageUri, 'grid')
                ?? this.imageUri;
        }
        return this.imageUriLarge
            ?? scryfallHiResFromStoredNormal(this.imageUri, 'grid')
            ?? this.imageUri;
    }
    public getCurrentPrice(): number | null {
        return this.priceUsd;
    }
    public getPriceUsdFoil(): number | null {
        return this.priceUsdFoil;
    }
    public getPriceEur(): number | null {
        return this.priceEur;
    }
    public getPriceEurFoil(): number | null {
        return this.priceEurFoil;
    }
    public getScryfallUri(): string | null {
        return this.scryfallUri;
    }

    public updatePrice(price: number | null): void {
        this.priceUsd = price;
    }

    // Constructs a Card domain object from a Sequelize model instance
    static fromModel(model: InstanceType<typeof CardModel>, isFoil = false): Card {
        const raw = model.get() as Record<string, unknown>;
        const instance = new Card();
        instance.scryfallId = raw.scryfallId as string;
        instance.name = raw.name as string | null;
        instance.setCode = raw.setCode as string | null;
        instance.setName = raw.setName as string | null;
        instance.collectorNumber = raw.collectorNumber as string | null;
        instance.lang = raw.lang as string | null;
        instance.manaCost = raw.manaCost as string | null;
        instance.cmc = raw.cmc !== null && raw.cmc !== undefined
            ? Number(raw.cmc)
            : null;
        instance.typeLine = raw.typeLine as string | null;
        instance.oracleText = raw.oracleText as string | null;
        instance.power = raw.power as string | null;
        instance.toughness = raw.toughness as string | null;
        instance.rarity = raw.rarity as string | null;
        instance.colors = (raw.colors as string[] | null) ?? [];
        instance.colorsIdentity = (raw.colorIdentity as string[] | null) ?? [];
        instance.imageUri = raw.imageUri as string | null;
        instance.imageUriLarge = (raw.imageUriLarge as string | null)
            ?? scryfallHiResFromStoredNormal(instance.imageUri, 'grid');
        instance.imageUriPng = (raw.imageUriPng as string | null)
            ?? scryfallHiResFromStoredNormal(instance.imageUri, 'detail');
        instance.priceUsd = raw.priceUsd as number | null;
        instance.priceUsdFoil = raw.priceUsdFoil as number | null;
        instance.priceEur = raw.priceEur as number | null;
        instance.priceEurFoil = raw.priceEurFoil as number | null;
        instance.scryfallUri = raw.scryfallUri as string | null;
        if (isFoil) {
            instance.priceUsd = instance.priceUsdFoil;
        }
        return instance;
    }
}
