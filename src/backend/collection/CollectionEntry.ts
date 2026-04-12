import Card from '../collection/Card'
export default class CollectionEntry{
    private card : Card;
    private quantity : number;
    private condition : string;
    private notes : string;

    constructor(data: {
        card:Card;
        quantity:number;
        condition : string;
        notes : string;

    }) {
        this.card = data.card;
        this.quantity = data.quantity;
        this.condition = data.condition;
        this.notes = data.notes;
    }
    public getCard() : Card {
        return this.card;
    }
    public getQuantity() : number{
        return this.quantity;
    }
    public getCondition(): string{
        return this.condition;
    }
    public getNotes(): string{
        return this.notes;
    }
    public updateQuantity(delta:number){
        if ( this.quantity - delta < 0 )
        {
            throw new Error("You don't have enough items ( quantity would be negative)")
        }
        this.quantity = this.quantity - delta;
    }
    public setCondition(condition : string){
        this.condition = condition;
    }
    public setNotes(notes:string)
    {
        this.notes = notes;
    }
}