import { Card as CardModel } from "../models/Card";

export default class ScryfallAdapter {
    private lastRequestTime: number = 0;
    // Ograniczenie narzucone przez Scryfall - rekomendowane 50-100ms opóźnienia między requestami
    private readonly RATE_LIMIT_MS = 100;

    private async waitForRateLimit(): Promise<void> {
        const now = Date.now();
        let delay = 0;

        if (now - this.lastRequestTime < this.RATE_LIMIT_MS) {
            delay = this.RATE_LIMIT_MS - (now - this.lastRequestTime);
        }

        // Reserve the next slot synchronously to avoid request bursts.
        this.lastRequestTime = now + delay;

        if (delay > 0) {
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }

    public async searchCard(cardName: string): Promise<any> {
        // Krok 1: Sprawdzenie, czy karta już istnieje w lokalnej bazie
        const dbCard = await CardModel.findOne({ where: { name: cardName } });
        if (dbCard) {
            return dbCard;
        }

        // Krok 2: Obsługa limitów zapytań (Rate Limiting)
        await this.waitForRateLimit();

        // Krok 3: Pytamy Scryfall API (zmiana na 'exact', aby cache w bazie działał poprawnie)
        const scryfallUrl = `https://api.scryfall.com/cards/named?exact=${encodeURIComponent(cardName)}`;
        const response = await fetch(scryfallUrl);

        if (response.status === 429) {
            throw new Error("Scryfall Rate Limit Exceeded");
        }

        if (!response.ok) {
            throw new Error(`Card ${cardName} not found`);
        }

        const data = await response.json();

        // Krok 4: Zapis do bazy
        const newCard = await CardModel.create({
            scryfallId: data.id,
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
            colorIdentity: data.color_identity,
            imageUri: data.image_uris?.normal,
            priceUsd: data.prices?.usd,
            priceUsdFoil: data.prices?.usd_foil,
            priceEur: data.prices?.eur,
            priceEurFoil: data.prices?.eur_foil,
            pricesUpdatedAt: new Date(),
            scryfallUri: data.scryfall_uri,
            fetchedAt: new Date(),
            updatedAt: new Date()
        });

        return newCard;
    }

    public async getPrice(scryfallId: string, isFoil = false): Promise<number | null> {
        await this.waitForRateLimit();

        const scryfallUrl = `https://api.scryfall.com/cards/${encodeURIComponent(scryfallId)}`;
        const response = await fetch(scryfallUrl);

        if (response.status === 429) {
            throw new Error("Scryfall Rate Limit Exceeded");
        }

        if (!response.ok) {
            throw new Error(`Card ${scryfallId} not found`);
        }

        const data = await response.json();
        const rawPrice = isFoil ? data.prices?.usd_foil : data.prices?.usd;

        if (rawPrice === null || rawPrice === undefined || rawPrice === '') {
            return null;
        }

        const parsedPrice = Number(rawPrice);
        if (Number.isNaN(parsedPrice)) {
            return null;
        }

        return parsedPrice;
    }
}