import JsonCacheProvider from "./JsonCacheProvider";
import ScryfallAdapter from "./ScryfallAdapter";
import Card from "../collection/Card";
export default class SmartAdapter {
    private scryfall! : ScryfallAdapter;
    private cache! : JsonCacheProvider;
    constructor(data?:{})
    {

    }
    public searchCard(query : string) : Card[]
    {
        return []
    }
    public getCardDetails(id : string): Card{
        return new Card()
    }
    public getPrice(scryfallId : string ): number {
        return 0;
    }

}