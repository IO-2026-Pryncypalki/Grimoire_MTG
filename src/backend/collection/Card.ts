export default class Card {
    private scryfallId : string;
    private name : string | null;
    private setCode: string | null ;
    private currentPrice: number | null;
    private imageUrl : string | null;

    constructor(data?: {
        scryfallId? : string;
        name? : string | null;
        setCode?: string | null;
        currentPrice?: number | null;
        imageUrl? : string | null;

    })
    {
        this.scryfallId = data?.scryfallId ?? "unknown-id";
        this.name = data?.name ?? null;
        this.setCode = data?.setCode ?? null;
        this.currentPrice = data?.currentPrice ?? null;
        this.imageUrl = data?.imageUrl ?? null;
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
    public getCurrentPrice(): number | null{
        return this.currentPrice;
    }
    public getImageUrl(): string | null{
        return this.imageUrl;
    }


}
