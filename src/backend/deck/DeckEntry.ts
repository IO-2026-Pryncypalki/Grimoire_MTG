import Card from '../collection/Card'
export default class DeckEntry {
    private card: Card;
    private quantity: number;
    private notes: string;

    constructor(data: { card: Card, quantity: number, notes: string }) {
        this.card = data.card;
        this.quantity = data.quantity;
        this.notes = data.notes;
    }
    public getCard() : Card {
        return this.card;
    }
    public getQuantity(): number {
        return this.quantity;
    }
    public getNotes(): string{
        return this.notes;
    }
    public updateQuantity(delta : number){
        if ( this.quantity - delta < 0)
        {
            throw Error("You don't have enough items ( quantity would be negative)")
        }
        this.quantity -= delta;
    }
    public setNotes(notes : string) {
        this.notes = notes;
    }
}