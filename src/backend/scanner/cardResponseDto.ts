import Card from '../collection/Card';

export interface CardDto {
  scryfallId: string;
  name: string | null;
  setCode: string | null;
  setName: string | null;
  collectorNumber: string | null;
  lang: string | null;
  imageUrl: string | null;
  imageUrlHiRes: string | null;
  price: number | null;
  releasedAt: string | null;
}

export interface CardDetailDto extends CardDto {
  manaCost: string | null;
  cmc: number | null;
  typeLine: string | null;
  oracleText: string | null;
  power: string | null;
  toughness: string | null;
  rarity: string | null;
  colors: string[];
  colorIdentity: string[];
  priceUsd: number | null;
  priceUsdFoil: number | null;
  priceEur: number | null;
  priceEurFoil: number | null;
  scryfallUri: string | null;
}

export function toCardDto(card: Card): CardDto {
  return {
    scryfallId: card.getScryfallId(),
    name: card.getName(),
    setCode: card.getSetCode(),
    setName: card.getSetName(),
    collectorNumber: card.getCollectorNumber(),
    lang: card.getLang(),
    imageUrl: card.getImageUrl(),
    imageUrlHiRes: card.getImageUrlHiRes('grid'),
    price: card.getCurrentPrice(),
    releasedAt: card.getReleasedAt(),
  };
}

export function toCardDetailDto(card: Card): CardDetailDto {
  const base = toCardDto(card);
  return {
    ...base,
    imageUrlHiRes: card.getImageUrlHiRes('detail'),
    manaCost: card.getManaCost(),
    cmc: card.getCmc(),
    typeLine: card.getTypeLine(),
    oracleText: card.getOracleText(),
    power: card.getPower(),
    toughness: card.getToughness(),
    rarity: card.getRarity(),
    colors: card.getColors(),
    colorIdentity: card.getColorIdentity(),
    priceUsd: card.getCurrentPrice(),
    priceUsdFoil: card.getPriceUsdFoil(),
    priceEur: card.getPriceEur(),
    priceEurFoil: card.getPriceEurFoil(),
    scryfallUri: card.getScryfallUri(),
  };
}
