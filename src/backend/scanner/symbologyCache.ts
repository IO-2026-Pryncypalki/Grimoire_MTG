import { scryfallFetch, SCRYFALL_BASE } from './scryfallHttp';

export interface SymbolEntry {
    symbol: string;
    svgUri: string;
}

export class SymbologyCache {
    private readonly map = new Map<string, string>();

    get size(): number {
        return this.map.size;
    }

    async loadFromScryfall(): Promise<void> {
        const res = await scryfallFetch(`${SCRYFALL_BASE}/symbology`);

        if (!res.ok) {
            throw new Error(`Scryfall /symbology failed: HTTP ${res.status}`);
        }

        const data = (await res.json()) as { data?: Array<{ symbol?: string; svg_uri?: string }> };
        const entries = data.data ?? [];

        for (const entry of entries) {
            if (entry.symbol && entry.svg_uri) {
                this.map.set(entry.symbol, entry.svg_uri);
            }
        }

        console.log(`Symbology map loaded (${this.map.size} symbols)`);
    }

    getUri(symbol: string): string | undefined {
        return this.map.get(symbol);
    }

    toList(): SymbolEntry[] {
        return Array.from(this.map.entries()).map(([symbol, svgUri]) => ({ symbol, svgUri }));
    }
}
