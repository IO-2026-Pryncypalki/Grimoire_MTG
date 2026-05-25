import JsonCacheProvider from "./JsonCacheProvider";
import ScryfallAdapter from "./ScryfallAdapter";
import Card from "../collection/Card";
export default class SmartAdapter {
    private scryfall! : ScryfallAdapter;
    private cache! : JsonCacheProvider;
    constructor(data?: { scryfall?: ScryfallAdapter; cache?: JsonCacheProvider })
    {
        this.scryfall = data?.scryfall ?? new ScryfallAdapter();
        this.cache = data?.cache ?? new JsonCacheProvider();
    }
    public searchCard(query : string) : Card[]
    {
        return []
    }
    public getCardDetails(id : string): Card{
        return new Card()
    }
    public async getPrice(scryfallId : string, isFoil = false): Promise<number | null> {
        return this.scryfall.getPrice(scryfallId, isFoil);
    }

}