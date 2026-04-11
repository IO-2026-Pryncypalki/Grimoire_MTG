import SmartAdapter from '../src/backend/adapters/SmartAdapter';

describe('SmartAdapter', () => {
  const makeCard = (id = 'abc-123') => ({
    scryfallId: id,
    name: 'Tarmogoyf',
    setCode: 'MH2',
    currentPrice: 10.0,
    imageUrl: 'https://example.com/card.jpg',
  });

  let scryfall;
  let cache;
  let adapter;

  beforeEach(() => {
    scryfall = {
      searchCard: jest.fn(),
      getCardDetails: jest.fn(),
      getPrice: jest.fn(),
    };
    cache = {
      isCachedMap: jest.fn(),
      isCachedFile: jest.fn(),
      getCard: jest.fn(),
      saveToCache: jest.fn(),
    };
    adapter = new SmartAdapter({ scryfall, cache });
  });

  describe('searchCard(query)', () => {
    test('zwraca wynik z cache gdy karta jest dostępna', async () => {
      const card = makeCard();
      cache.isCachedMap.mockReturnValue(true);
      cache.getCard.mockReturnValue([card]);
      const result = await adapter.searchCard('Tarmogoyf');
      expect(result).toEqual([card]);
      expect(scryfall.searchCard).not.toHaveBeenCalled();
    });

    test('odpytuje Scryfall gdy karty nie ma w cache', async () => {
      const card = makeCard();
      cache.isCachedMap.mockReturnValue(false);
      cache.isCachedFile.mockReturnValue(false);
      scryfall.searchCard.mockResolvedValue([card]);
      const result = await adapter.searchCard('Tarmogoyf');
      expect(scryfall.searchCard).toHaveBeenCalledWith('Tarmogoyf');
      expect(result).toEqual([card]);
    });

    test('zapisuje wynik w cache po pobraniu ze Scryfall', async () => {
      const card = makeCard();
      cache.isCachedMap.mockReturnValue(false);
      cache.isCachedFile.mockReturnValue(false);
      scryfall.searchCard.mockResolvedValue([card]);
      await adapter.searchCard('Tarmogoyf');
      expect(cache.saveToCache).toHaveBeenCalled();
    });

    test('propaguje błąd gdy Scryfall rzuca wyjątek', async () => {
      cache.isCachedMap.mockReturnValue(false);
      cache.isCachedFile.mockReturnValue(false);
      scryfall.searchCard.mockRejectedValue(new Error('API error'));
      await expect(adapter.searchCard('Tarmogoyf')).rejects.toThrow('API error');
    });
  });

  describe('getCardDetails(id)', () => {
    test('zwraca szczegóły z cache gdy dostępne', async () => {
      const card = makeCard();
      cache.isCachedMap.mockReturnValue(true);
      cache.getCard.mockReturnValue(card);
      const result = await adapter.getCardDetails('abc-123');
      expect(result).toEqual(card);
      expect(scryfall.getCardDetails).not.toHaveBeenCalled();
    });

    test('odpytuje Scryfall i zapisuje w cache gdy brak w cache', async () => {
      const card = makeCard();
      cache.isCachedMap.mockReturnValue(false);
      cache.isCachedFile.mockReturnValue(false);
      scryfall.getCardDetails.mockResolvedValue(card);
      const result = await adapter.getCardDetails('abc-123');
      expect(scryfall.getCardDetails).toHaveBeenCalledWith('abc-123');
      expect(cache.saveToCache).toHaveBeenCalled();
      expect(result).toEqual(card);
    });
  });

  describe('getPrice(scryfallId)', () => {
    test('zawsze odpytuje Scryfall (ceny nie są cachowane)', async () => {
      scryfall.getPrice.mockResolvedValue(42.0);
      const result = await adapter.getPrice('abc-123');
      expect(scryfall.getPrice).toHaveBeenCalledWith('abc-123');
      expect(result).toBe(42.0);
    });

    test('propaguje błąd gdy Scryfall rzuca wyjątek', async () => {
      scryfall.getPrice.mockRejectedValue(new Error('API error'));
      await expect(adapter.getPrice('abc-123')).rejects.toThrow('API error');
    });
  });
});