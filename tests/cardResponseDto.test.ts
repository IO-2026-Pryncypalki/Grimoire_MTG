import Card from '../src/backend/collection/Card';
import { toCardDetailDto, toCardDto } from '../src/backend/scanner/cardResponseDto';

describe('toCardDto', () => {
  test('mapuje pola potrzebne do pickera wydruków', () => {
    const card = new Card({
      id: 'abc-123',
      name: 'Lightning Bolt',
      set: 'tsr',
      set_name: 'Time Spiral Remastered',
      collector_number: '333',
      lang: 'en',
      image_uris: { normal: 'https://example.com/bolt.jpg' },
      prices: { usd: 1.5, usd_foil: 2, eur: 1.2, eur_foil: 2.5 },
    });

    expect(toCardDto(card)).toEqual({
      scryfallId: 'abc-123',
      name: 'Lightning Bolt',
      setCode: 'tsr',
      setName: 'Time Spiral Remastered',
      collectorNumber: '333',
      lang: 'en',
      imageUrl: 'https://example.com/bolt.jpg',
      price: 1.5,
    });
  });
});

describe('toCardDetailDto', () => {
  test('mapuje pełne szczegóły karty', () => {
    const card = new Card({
      id: 'abc-123',
      name: 'Lightning Bolt',
      set: 'tsr',
      set_name: 'Time Spiral Remastered',
      collector_number: '333',
      lang: 'en',
      mana_cost: '{R}',
      cmc: 1,
      type_line: 'Instant',
      oracle_text: 'Lightning Bolt deals 3 damage to any target.',
      rarity: 'common',
      colors: ['R'],
      colors_identity: ['R'],
      image_uris: { normal: 'https://example.com/bolt.jpg' },
      prices: { usd: 1.5, usd_foil: 2, eur: 1.2, eur_foil: 2.5 },
      scryfall_uri: 'https://scryfall.com/card/tsr/333',
    });

    expect(toCardDetailDto(card)).toEqual({
      scryfallId: 'abc-123',
      name: 'Lightning Bolt',
      setCode: 'tsr',
      setName: 'Time Spiral Remastered',
      collectorNumber: '333',
      lang: 'en',
      imageUrl: 'https://example.com/bolt.jpg',
      price: 1.5,
      manaCost: '{R}',
      cmc: 1,
      typeLine: 'Instant',
      oracleText: 'Lightning Bolt deals 3 damage to any target.',
      power: null,
      toughness: null,
      rarity: 'common',
      colors: ['R'],
      colorIdentity: ['R'],
      priceUsd: 1.5,
      priceUsdFoil: 2,
      priceEur: 1.2,
      priceEurFoil: 2.5,
      scryfallUri: 'https://scryfall.com/card/tsr/333',
    });
  });
});
