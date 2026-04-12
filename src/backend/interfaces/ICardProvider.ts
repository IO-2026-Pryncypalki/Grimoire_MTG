import Card from '../collection/Card'
export default interface ICardProvider{
     searchCard(query : string): Card [];
     getCardDetails(id : string): Card;
     getPrice(scryfallId: string) : number;
}