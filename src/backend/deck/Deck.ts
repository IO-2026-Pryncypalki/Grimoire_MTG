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
    public getCard(scryfallId : string): DeckEntry | null
    {
        return this.cards.find((entry) => entry.getCard().getScryfallId() === scryfallId) ?? null;
    }
    public addCard(card : Card,count : number){
        if (count <= 0) {
            throw new Error('Card quantity must be greater than 0');
        }
        const existingEntry = this.getCard(card.getScryfallId());
        if (existingEntry) {
            existingEntry.updateQuantity(count);
            return;
        }
        this.cards.push(new DeckEntry({ card, quantity: count, notes: '' }));
    }
    public removeCard(scryfallId : string){
        this.cards = this.cards.filter((entry) => entry.getCard().getScryfallId() !== scryfallId);
    }
    public validate(validator : IDeckValidator): boolean{
        return validator.isValid(this, this.format);
    }
    public async searchNewCards(query : string,provider : ICardProvider): Promise<Card[]>
    {
        return provider.searchCard(query);
    }
}