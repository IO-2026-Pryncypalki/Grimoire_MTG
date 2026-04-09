const ScannerService = require('../src/scanner/ScannerService');

describe('ScannerService', () => {
  const makeCard = () => ({
    scryfallId: 'xyz',
    name: 'Tarmogoyf',
    setCode: 'MH2',
  });

  let mlKitAdapter;
  let provider;
  let service;

  beforeEach(() => {
    mlKitAdapter = { recognizeText: jest.fn() };
    provider = { searchCard: jest.fn() };
    service = new ScannerService({ mlKitAdapter });
  });

  test('wywołuje mlKitAdapter.recognizeText z obrazem', async () => {
    mlKitAdapter.recognizeText.mockResolvedValue('Tarmogoyf');
    provider.searchCard.mockResolvedValue([makeCard()]);
    await service.processScan('image-data', provider);
    expect(mlKitAdapter.recognizeText).toHaveBeenCalledWith('image-data');
  });

  test('wywołuje provider.searchCard z rozpoznaną nazwą', async () => {
    mlKitAdapter.recognizeText.mockResolvedValue('Tarmogoyf');
    provider.searchCard.mockResolvedValue([makeCard()]);
    await service.processScan('image-data', provider);
    expect(provider.searchCard).toHaveBeenCalledWith('Tarmogoyf');
  });

  test('zwraca pierwszą pasującą kartę', async () => {
    const card = makeCard();
    mlKitAdapter.recognizeText.mockResolvedValue('Tarmogoyf');
    provider.searchCard.mockResolvedValue([card]);
    const result = await service.processScan('image-data', provider);
    expect(result).toEqual(card);
  });

  test('rzuca błąd gdy OCR zwraca pusty string', async () => {
    mlKitAdapter.recognizeText.mockResolvedValue('');
    await expect(service.processScan('image-data', provider)).rejects.toThrow();
  });

  test('rzuca błąd gdy Scryfall nie znalazł karty', async () => {
    mlKitAdapter.recognizeText.mockResolvedValue('NieistniejącaKarta');
    provider.searchCard.mockResolvedValue([]);
    await expect(service.processScan('image-data', provider)).rejects.toThrow();
  });
});
