import Card from "./Card"
import CollectionEntry from "./CollectionEntry";
import ICardProvider from "../interfaces/ICardProvider"
export default class Collection {

    private userId : string;
    private entries : CollectionEntry[] = [];

    constructor(data: {userId: string,entries?:CollectionEntry[]})
    {
        this.userId = data.userId;
        if ( data.entries) {
            this.entries = data.entries;
        }
    }
    public addCard(card: Card | null){
        if ( !card)
        {
            throw Error("You can't add null");
        }
    }
    public removeCard(scryfallId: string){

    }
    public getEntry(scryfallId : string):CollectionEntry
    {
        return this.entries[0];
    }
    public getEntries() : CollectionEntry[]{
        return this.entries;
    }
    public calculateTotalValue(): number{
        return 2137;
    }
    public refreshPrices(provider : ICardProvider){

    }
};