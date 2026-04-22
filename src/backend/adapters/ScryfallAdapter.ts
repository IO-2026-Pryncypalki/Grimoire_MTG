import IHttpClient from "../interfaces/IHttpClient";
import Card,{Price} from "../collection/Card";

import {CardModel} from "../models/CardModel";
import {Request,Response} from 'express'

export default class ScryfallAdapter{
   // private client :IHttpClient;
    public async searchCard(cardName : string) : Promise<any>
    {
        const dbCards = await CardModel.findAll({where:{name:cardName}});
        if (dbCards){
             return dbCards.map((dbCard: any) => new Card({
                id: dbCard.id,
                name: dbCard.name,
                set: dbCard.setCode,
                set_name: dbCard.setName,
                collector_number: dbCard.collectorNumber,
                lang: dbCard.lang,
                mana_cost: dbCard.manaCost,
                cmc: dbCard.cmc,
                type_line: dbCard.typeLine,
                oracle_id: dbCard.oracleText,
                power: dbCard.power,
                toughness: dbCard.toughness,
                rarity: dbCard.rarity,
                colors: dbCard.colors,
                colors_identity: dbCard.colorsIdentity,
                image_uris: {normal: dbCard.imageUri},
                 prices: {
                     usd: dbCard.priceUsd,
                     usd_foil: dbCard.priceUsdFoil,
                     eur: dbCard.priceEur,
                     eur_foil: dbCard.priceEurFoil
                 },
                scryfall_uri: dbCard.scryfallUri
            }));
        ;
        }
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