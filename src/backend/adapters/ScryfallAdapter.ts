import IHttpClient from "../interfaces/IHttpClient";
import Card from "../collection/Card";
import {Request,Response} from 'express'

export default class ScryfallAdapter{
   // private client :IHttpClient;
    public async searchCard(cardName : string) : Promise<Card>
    {

        const scryfallUrl = `https://api.scryfall.com/cards/named?exact=${encodeURIComponent(cardName)}`
        const response = await fetch(scryfallUrl);
        if (!response.ok)
        {
            throw new Error("Blad API");
        }
        const data = await response.json();
        return new Card(data)
    }
    public getCardDetails(id : string): Card{
        return new Card();
    }
    public getPrice(scryfallId : string): number {
        return 0;
    }

}