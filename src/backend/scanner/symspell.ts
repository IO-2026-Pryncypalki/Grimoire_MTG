/**
 * Cienka nakładka na node-symspell dostosowana do korekcji nazw kart MTG.
 * Indeks ~27k nazw buduje się w ~350ms (vs RangeError przy własnym DELETE-n).
 */

import { unlink, writeFile } from 'fs/promises';
import { tmpdir } from 'os';
import { join } from 'path';

import SymSpellLib from 'node-symspell';

import { scryfallFetch, SCRYFALL_BASE } from './scryfallHttp';

/** Dystans edycji — zmień tutaj, by dostroić czułość korekty OCR. */
export const SYM_SPELL_MAX_EDIT = 3;
export const SYM_SPELL_PREFIX_LEN = 7;

export interface SymSpellSuggestion {
  term: string;
  distance: number;
}

async function loadDictionaryFromNames(
  ss: InstanceType<typeof SymSpellLib>,
  names: string[],
): Promise<void> {
  const dictPath = join(tmpdir(), `mtg-dict-${Date.now()}-${Math.random().toString(36).slice(2)}.tsv`);
  const body = names.map((n) => `${n.toLowerCase()}\t1`).join('\n');

  try {
    await writeFile(dictPath, body);
    await ss.loadDictionary(dictPath, 0, 1, '\t');
  } finally {
    await unlink(dictPath).catch(() => undefined);
  }
}

export class CardSymSpell {
  private readonly ss: InstanceType<typeof SymSpellLib>;
  private _size = 0;

  constructor(
    maxEditDistance = SYM_SPELL_MAX_EDIT,
    prefixLength = SYM_SPELL_PREFIX_LEN,
  ) {
    this.ss = new SymSpellLib(maxEditDistance, prefixLength);
  }

  get size(): number {
    return this._size;
  }

  static async fromNames(names: string[]): Promise<CardSymSpell> {
    const ss = new CardSymSpell();
    await loadDictionaryFromNames(ss.ss, names);
    ss._size = names.length;
    return ss;
  }

  async loadFromScryfall(): Promise<void> {
    const res = await scryfallFetch(`${SCRYFALL_BASE}/catalog/card-names`);

    if (!res.ok) {
      throw new Error(`Scryfall catalog/card-names failed: HTTP ${res.status}`);
    }

    const data = (await res.json()) as { data?: string[] };
    const names = data.data ?? [];

    process.stdout.write(`Building SymSpell index (${names.length} names)…`);
    const t0 = Date.now();
    await loadDictionaryFromNames(this.ss, names);
    process.stdout.write(` done (${Date.now() - t0} ms)\n`);
    this._size = names.length;
  }

  lookup(input: string, limit = 5): SymSpellSuggestion[] {
    const query = input.trim();
    if (!query) return [];

    const results = this.ss.lookup(query.toLowerCase(), 1, SYM_SPELL_MAX_EDIT);
    return results.slice(0, limit).map((r) => ({
      term: r.term,
      distance: r.distance,
    }));
  }
}

export async function buildFromScryfall(): Promise<CardSymSpell> {
  const ss = new CardSymSpell();
  await ss.loadFromScryfall();
  return ss;
}
