import { CardModel } from "../models/CardModel";

export default class ScryfallAdapter {
    private lastRequestTime: number = 0;
    // Ograniczenie narzucone przez Scryfall - rekomendowane 50-100ms opóźnienia między requestami
    private readonly RATE_LIMIT_MS = 100;

    public async searchCard(cardName: string): Promise<any> {
        //Sprawdzenie, czy karta już istnieje w naszej lokalnej bazie
        const dbCard = await CardModel.findOne({ where: { name: cardName } });
        if (dbCard) {
            return dbCard;
        }

        // Krok 2: Obsługa limitów zapytań (Rate Limiting)
        const now = Date.now();
        const timeSinceLastRequest = now - this.lastRequestTime;

        if (timeSinceLastRequest < this.RATE_LIMIT_MS) {
            const delay = this.RATE_LIMIT_MS - timeSinceLastRequest;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
        this.lastRequestTime = Date.now();

        // Krok 3: Pytamy Scryfall API
        const scryfallUrl = `https://api.scryfall.com/cards/named?fuzzy=${encodeURIComponent(cardName)}`;
        const response = await fetch(scryfallUrl);

        if (response.status === 429) {
            throw new Error("Scryfall Rate Limit Exceeded");
        }

        if (!response.ok) {
            throw new Error(`Card ${cardName} not found`);
        }

        const data = await response.json();


        const newCard = await CardModel.create({
            id: data.id,
            name: data.name,
            setCode: data.set,
            setName: data.set_name,
            collectorNumber: data.collector_number,
            lang: data.lang,
            manaCost: data.mana_cost,
            cmc: data.cmc,
            typeLine: data.type_line,
            oracleText: data.oracle_text,
            power: data.power,
            toughness: data.toughness,
            rarity: data.rarity,
            colors: data.colors,
            colorsIdentity: data.color_identity,
            imageUri: data.image_uris?.normal,
            priceUsd: data.prices?.usd,
            priceUsdFoil: data.prices?.usd_foil,
            priceEur: data.prices?.eur,
            priceEurFoil: data.prices?.eur_foil,
            scryfallUri: data.scryfall_uri,
            fetchedAt: new Date(),
            updatedAt: new Date()
        });

        return newCard;
    }
}