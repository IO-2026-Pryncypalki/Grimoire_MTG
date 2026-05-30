import Card from '../collection/Card'
export default interface ICardProvider{
     searchCard(query : string): Promise<Card[]>;
     getCardDetails(id : string): Promise<Card>;
     getPrice(scryfallId: string, isFoil?: boolean) : Promise<number | null>;
}