export const SCRYFALL_BASE = 'https://api.scryfall.com';
export const SCRYFALL_UA = 'GrimoireMTG/1.0 contact:github.com/grimoire-mtg';

export async function scryfallFetch(
  url: string,
  init?: RequestInit,
): Promise<Response> {
  return fetch(url, {
    ...init,
    headers: {
      Accept: 'application/json',
      'User-Agent': SCRYFALL_UA,
      ...init?.headers,
    },
  });
}
