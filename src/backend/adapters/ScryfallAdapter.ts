export default class ScryfallAdapter {
    private lastRequestTime: number = 0;
    private readonly RATE_LIMIT_MS = 100;

    private async waitForRateLimit(): Promise<void> {
        const now = Date.now();
        let delay = 0;

        if (now - this.lastRequestTime < this.RATE_LIMIT_MS) {
            delay = this.RATE_LIMIT_MS - (now - this.lastRequestTime);
        }

        this.lastRequestTime = now + delay;

        if (delay > 0) {
            await new Promise(resolve => setTimeout(resolve, delay));
        }
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
