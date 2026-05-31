import ScannerService from '../src/backend/scanner/ScannerService';
import Card from '../src/backend/collection/Card';

describe('ScannerService', () => {
  const makeCard = () =>
    new Card({
      id: 'xyz',
      name: 'Tarmogoyf',
      set: 'MH2',
      set_name: 'Modern Horizons 2',
      collector_number: '136',
      image_uris: { normal: 'https://example.com/tarmo.jpg' },
      prices: { usd: 10, usd_foil: 0, eur: 0, eur_foil: 0 },
    });

  let resolver;
  let service: ScannerService;

  beforeEach(() => {
    resolver = { resolve: jest.fn() };
    service = new ScannerService({ resolver });
  });

  test('parsuje plaintext i deleguje do resolvera', async () => {
    const card = makeCard();
    resolver.resolve.mockResolvedValue({ cards: [card], total: 1 });

    const plaintext = ['Tarmogoyf', 'Creature', '136/303', 'MH2 • EN'].join('\n');
    const result = await service.scanFromPlaintext(plaintext);

    expect(resolver.resolve).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'Tarmogoyf',
        set: 'MH2',
        collectorNumber: '136/303',
      }),
    );
    expect(result.parsed.name).toBe('Tarmogoyf');
    expect(result.cards).toEqual([card]);
    expect(result.total).toBe(1);
    expect(result.resolution).toBe('unique');
  });

  test('resolution=ambiguous gdy resolver zwraca wiele kart', async () => {
    const second = new Card({
      id: 'abc-2',
      name: 'Lightning Bolt',
      set: 'TSR',
      prices: { usd: 1, usd_foil: 0, eur: 0, eur_foil: 0 },
    });
    const cards = [makeCard(), second];
    resolver.resolve.mockResolvedValue({ cards, total: 42 });

    const result = await service.scanFromPlaintext('Lightning Bolt\nInstant');

    expect(result.cards).toHaveLength(2);
    expect(result.total).toBe(42);
    expect(result.resolution).toBe('ambiguous');
  });

  test('resolution=none gdy resolver nic nie znalazł', async () => {
    resolver.resolve.mockResolvedValue({ cards: [], total: 0 });

    const result = await service.scanFromPlaintext('Unknown Card\nInstant');

    expect(result.cards).toEqual([]);
    expect(result.total).toBe(0);
    expect(result.resolution).toBe('none');
  });

  test('rzuca błąd gdy plaintext jest pusty', async () => {
    await expect(service.scanFromPlaintext('')).rejects.toThrow('Plaintext is required');
    await expect(service.scanFromPlaintext('   ')).rejects.toThrow('Plaintext is required');
    expect(resolver.resolve).not.toHaveBeenCalled();
  });
});
