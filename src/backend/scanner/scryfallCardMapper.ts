import Card, { Price } from '../collection/Card';

function parseScryfallPrice(value: unknown): number | null {
  if (value === null || value === undefined || value === '') {
    return null;
  }
  const parsed = Number(value);
  return Number.isNaN(parsed) ? null : parsed;
}

function resolveImageUri(data: Record<string, unknown>): string | null {
  const imageUris = data.image_uris as { normal?: string } | null | undefined;
  if (imageUris?.normal) {
    return imageUris.normal;
  }
  const faces = data.card_faces as Array<{ image_uris?: { normal?: string } }> | undefined;
  return faces?.[0]?.image_uris?.normal ?? null;
}

/** Fields for Sequelize CardModel.create from Scryfall API JSON */
export function scryfallJsonToCardModelFields(data: Record<string, unknown>) {
  const prices = data.prices as Record<string, string | null> | null | undefined;
  const now = new Date();

  return {
    scryfallId: data.id as string,
    name: data.name as string,
    setCode: data.set as string,
    setName: data.set_name as string,
    collectorNumber: data.collector_number as string,
    lang: (data.lang as string | null) ?? null,
    manaCost: (data.mana_cost as string | null) ?? null,
    cmc: (data.cmc as number | null) ?? null,
    typeLine: (data.type_line as string | null) ?? null,
    oracleText: (data.oracle_text as string | null) ?? null,
    power: (data.power as string | null) ?? null,
    toughness: (data.toughness as string | null) ?? null,
    rarity: (data.rarity as string | null) ?? null,
    colors: (data.colors as string[] | null) ?? null,
    colorIdentity: (data.color_identity as string[] | null) ?? null,
    imageUri: resolveImageUri(data),
    priceUsd: parseScryfallPrice(prices?.usd),
    priceUsdFoil: parseScryfallPrice(prices?.usd_foil),
    priceEur: parseScryfallPrice(prices?.eur),
    priceEurFoil: parseScryfallPrice(prices?.eur_foil),
    pricesUpdatedAt: now,
    scryfallUri: (data.scryfall_uri as string | null) ?? null,
    fetchedAt: now,
    updatedAt: now,
  };
}

function mapScryfallPrices(data: Record<string, unknown>): Price | null {
  const raw = data.prices as Record<string, string | null> | null | undefined;
  if (!raw) {
    return null;
  }
  return {
    usd: parseScryfallPrice(raw.usd) ?? 0,
    usd_foil: parseScryfallPrice(raw.usd_foil) ?? 0,
    eur: parseScryfallPrice(raw.eur) ?? 0,
    eur_foil: parseScryfallPrice(raw.eur_foil) ?? 0,
  };
}

export function mapScryfallJsonToCard(data: Record<string, unknown>): Card {
  const imageUri = resolveImageUri(data);
  return new Card({
    id: data.id as string,
    name: data.name as string,
    set: data.set as string,
    set_name: data.set_name as string,
    collector_number: data.collector_number as string,
    lang: data.lang as string,
    mana_cost: (data.mana_cost as string | null) ?? null,
    cmc: (data.cmc as number | null) ?? null,
    type_line: (data.type_line as string | null) ?? null,
    oracle_text: (data.oracle_text as string | null) ?? null,
    power: (data.power as string | null) ?? null,
    toughness: (data.toughness as string | null) ?? null,
    rarity: (data.rarity as string | null) ?? null,
    colors: data.colors as string[] | undefined,
    colors_identity: data.color_identity as string[] | undefined,
    image_uris: imageUri ? { normal: imageUri } : null,
    prices: mapScryfallPrices(data),
    scryfall_uri: (data.scryfall_uri as string | null) ?? null,
  });
}
