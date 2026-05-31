import ScryfallScanResolver from '../src/backend/scanner/ScryfallScanResolver';

const scryfallCard = (overrides: Record<string, unknown> = {}) => ({
  id: 'abc-123',
  name: 'Lightning Bolt',
  set: 'tsr',
  set_name: 'Time Spiral Remastered',
  collector_number: '333',
  lang: 'en',
  mana_cost: '{R}',
  cmc: 1,
  type_line: 'Instant',
  oracle_text: 'Deal 3 damage.',
  rarity: 'common',
  image_uris: { normal: 'https://example.com/bolt.jpg' },
  prices: { usd: '1.50', usd_foil: '2.00', eur: '1.20', eur_foil: '2.50' },
  scryfall_uri: 'https://scryfall.com/card/tsr/333',
  ...overrides,
});

describe('ScryfallScanResolver', () => {
  let fetchMock: jest.Mock;
  let resolver: ScryfallScanResolver;

  beforeEach(() => {
    fetchMock = jest.fn();
    global.fetch = fetchMock;
    resolver = new ScryfallScanResolver(0);
  });

  const mockJsonResponse = (status: number, body: unknown, headers: Record<string, string> = {}) => {
    const normalized: Record<string, string> = {};
    for (const [k, v] of Object.entries(headers)) {
      normalized[k.toLowerCase()] = v;
    }
    return {
      status,
      ok: status >= 200 && status < 300,
      headers: {
        get: (key: string) => normalized[key.toLowerCase()] ?? null,
      },
      json: async () => body,
    };
  };

  test('krok 1: set + collector zwraca jedną kartę bez dalszych zapytań', async () => {
    fetchMock.mockResolvedValueOnce(
      mockJsonResponse(200, scryfallCard()),
    );

    const result = await resolver.resolve({
      name: 'Lightning Bolt',
      set: 'TSR',
      collectorNumber: '0333',
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe('https://api.scryfall.com/cards/tsr/333');
    expect(result.total).toBe(1);
    expect(result.cards[0].getName()).toBe('Lightning Bolt');
    expect(result.cards[0].getSetCode()).toBe('tsr');
  });

  test('krok 2: exact name+set search gdy set+collector zwraca 404', async () => {
    fetchMock
      .mockResolvedValueOnce(mockJsonResponse(404, {}))
      .mockResolvedValueOnce(
        mockJsonResponse(200, {
          total_cards: 2,
          data: [
            scryfallCard({ id: 'a', collector_number: '1' }),
            scryfallCard({ id: 'b', collector_number: '2' }),
          ],
        }),
      );

    const result = await resolver.resolve({
      name: 'Lightning Bolt',
      set: 'TSR',
      collectorNumber: '999',
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toContain('/cards/search?q=');
    expect(fetchMock.mock.calls[1][0]).toContain('e%3Atsr');
    expect(result.total).toBe(2);
    expect(result.cards).toHaveLength(2);
  });

  test('krok 2 fallback: fuzzy name+set gdy exact search zwraca 404', async () => {
    fetchMock
      .mockResolvedValueOnce(mockJsonResponse(404, {}))
      .mockResolvedValueOnce(mockJsonResponse(404, {}))
      .mockResolvedValueOnce(mockJsonResponse(200, scryfallCard({ name: 'Lightning Bolt' })));

    const result = await resolver.resolve({
      name: 'Lightnng Bolt',
      set: 'TSR',
      collectorNumber: '999',
    });

    expect(fetchMock).toHaveBeenCalledTimes(3);
    expect(fetchMock.mock.calls[2][0]).toContain('/cards/named?fuzzy=');
    expect(result.total).toBe(1);
  });

  test('krok 3: exact name only gdy brak setu', async () => {
    fetchMock.mockResolvedValueOnce(
      mockJsonResponse(200, {
        total_cards: 3,
        data: [
          scryfallCard({ id: 'x', set: 'lea' }),
          scryfallCard({ id: 'y', set: 'leb' }),
          scryfallCard({ id: 'z', set: '2ed' }),
        ],
      }),
    );

    const result = await resolver.resolve({ name: 'Lightning Bolt' });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toContain('/cards/search?q=');
    expect(result.total).toBe(3);
    expect(result.cards).toHaveLength(3);
  });

  test('krok 3 fallback: fuzzy name gdy exact search pusty', async () => {
    fetchMock
      .mockResolvedValueOnce(mockJsonResponse(404, {}))
      .mockResolvedValueOnce(mockJsonResponse(200, scryfallCard()));

    const result = await resolver.resolve({ name: 'Lightnng Bolt' });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(fetchMock.mock.calls[1][0]).toBe(
      'https://api.scryfall.com/cards/named?fuzzy=Lightnng%20Bolt',
    );
    expect(result.total).toBe(1);
  });

  test('zwraca pusty wynik gdy nic nie pasuje', async () => {
    fetchMock
      .mockResolvedValueOnce(mockJsonResponse(404, {}))
      .mockResolvedValueOnce(mockJsonResponse(404, {}));

    const result = await resolver.resolve({ name: 'Nieistniejąca Karta XYZ' });

    expect(result).toEqual({ cards: [], total: 0 });
  });

  test('429 po wyczerpaniu retry rzuca błąd rate limit', async () => {
    fetchMock.mockResolvedValue(
      mockJsonResponse(429, {}, { 'Retry-After': '0' }),
    );

    await expect(
      resolver.resolve({ name: 'Lightning Bolt' }),
    ).rejects.toThrow('Scryfall Rate Limit Exceeded');
  });
});
