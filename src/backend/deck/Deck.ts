import DeckEntry from "./DeckEntry";
import Card from '../collection/Card'
import IDeckValidator from "../interfaces/IDeckValidator";
import ICardProvider from "../interfaces/ICardProvider";
export default class Deck {
    private  id : string;
    private  name : string;
    private format : string;
    private cards : DeckEntry[] = [];

    constructor(data:{id : string,name: string,format:string,cards?: DeckEntry[]})
    {
        this.id = data.id;
        this.name = data.name;
        this.format = data.format;
        this.cards = data?.cards ?? [];
    }
    public getId() : string{
        return this.id;
    }
    public getName(): string{
        return this.name;
    }
    public getFormat(): string{
        return this.format;
    }
    public getCards(): DeckEntry[]{
    return this.cards;
    }
    public getCard(scryfallId : string): DeckEntry
    {
        return this.cards[0];
    }
    public addCard(card : Card,count : number){

    }
    public removeCard(scryfallId : string){

    }
    public validate(validator : IDeckValidator): boolean{
        return false;
    }
    public searchNewCards(query : string,provider : ICardProvider): Card[]
    {
        return [];
    }
}