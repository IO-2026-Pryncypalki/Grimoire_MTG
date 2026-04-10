import IHttpClient from "../interfaces/IHttpClient";
import Card from "../collection/Card";
export default class ScryfallAdapter{
    private client :IHttpClient;
    public searchCard(query : string) : Card []
    {
        return []
    }
    public getCardDetails(id : string): Card{
        return new Card();
    }
    public getPrice(scryfallId : string): number {
        return 0;
    }

}