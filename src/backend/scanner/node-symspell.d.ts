declare module 'node-symspell' {
  export interface SymSpellLookupResult {
    term: string;
    distance: number;
    count?: number;
  }

  export default class SymSpell {
    constructor(maxDictionaryEditDistance?: number, prefixLength?: number, countThreshold?: number);
    loadDictionary(
      dictFile: string,
      termIndex: number,
      countIndex: number,
      separator?: string,
    ): Promise<void>;
    lookup(
      input: string,
      verbosity: number,
      maxEditDistance?: number | null,
      options?: Record<string, unknown>,
    ): SymSpellLookupResult[];
  }
}
