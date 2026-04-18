interface Price{
    usd : number
    usdFoil : number
    eur : number
    eurFoil : number
}
export default class Card {
    private scryfallId : string;
    private name : string | null;
    private setCode: string | null;
    private setName: string | null;
    private collectorNumber : string | null;
    private lang : string | null;
    private manaCost : string | null;
    private cmc : number | null;
    private typeLine : string | null;
    private oracleText : string | null;
    private power : string | null;
    private toughness : string | null;
    private rarity : number | null;
    private colors : string[] = []
    private colorsIdentity : string[] = []
    private imageUri : string[] | null;
    private currentPrice : Price | null;
    private scryfallUri : string | null;

    constructor(data?: {
        id : string,
        name : string | null,
        set_code: string | null,
        set_name: string | null,
        collector_number : string | null,
        lang : string | null,
        mana_cost : string | null,
        cmc : number | null,
        type_line : string | null,
        oracle_id : string | null,
        power?: string | null,
        toughness? : string | null,
        rarity? : number | null,
        colors? : string[],
        colors_identity? : string[],
        image_uris? : string[] | null,
        prices? : Price | null,
        scryfall_uri? : string | null,

    })
    {
        this.scryfallId = data?.id?? "unknown-id";
        this.name = data?.name ?? null;
        this.setCode = data?.set_code ?? null;
        this.setName = data?.set_name ?? null;
        this.collectorNumber = data?.collector_number ?? null,
        this.lang = data?.lang ?? null,
        this.manaCost =  data?.mana_cost ?? null,
        this.cmc = data?.cmc ?? null,
        this.typeLine = data?.type_line ?? null,
        this.oracleText = data?.oracle_id ?? null,
        this.power = data?.power ?? null,
        this.toughness = data?.toughness ?? null,
        this.rarity = data?.rarity ?? null;
        if(data?.colors) this.colors = data?.colors;
        if (data?.colors_identity)  this.colorsIdentity = data?.colors_identity;
        this.imageUri = data?.image_uris ?? null,
        this.currentPrice = data?.prices ?? null;
        this.scryfallUri = data?.scryfall_uri ?? null;
    }
    public getScryfallId() : string {
        return this.scryfallId
    }
    public getName(): string | null{
        return this.name;
    }
    public getSetCode(): string | null{
        return this.setCode;
    }
    public getCurrentPrice(): Price | null{
        return this.currentPrice;
    }
    public getImageUrl(): string[] | null{
        return this.imageUri;
    }
}
