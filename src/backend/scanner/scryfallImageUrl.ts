export type ScryfallImageVariant = 'grid' | 'detail';

type ScryfallImageUris = {
  png?: string;
  large?: string;
  normal?: string;
};

function pickImageUri(
  uris: ScryfallImageUris | null | undefined,
  variant: ScryfallImageVariant,
): string | null {
  if (!uris) {
    return null;
  }
  if (variant === 'detail') {
    return uris.png ?? uris.large ?? uris.normal ?? null;
  }
  return uris.large ?? uris.normal ?? null;
}

function imageUrisFromData(data: Record<string, unknown>): ScryfallImageUris | null {
  const top = data.image_uris as ScryfallImageUris | null | undefined;
  if (top) {
    return top;
  }
  const faces = data.card_faces as Array<{ image_uris?: ScryfallImageUris }> | undefined;
  return faces?.[0]?.image_uris ?? null;
}

/** Hi-res URL from Scryfall API JSON (grid: large; detail: png). */
export function resolveHiResImageUri(
  data: Record<string, unknown>,
  variant: ScryfallImageVariant = 'grid',
): string | null {
  return pickImageUri(imageUrisFromData(data), variant);
}

/** Derive hi-res URL from a stored normal Scryfall CDN link. */
export function scryfallHiResFromStoredNormal(
  url: string | null | undefined,
  variant: ScryfallImageVariant = 'grid',
): string | null {
  if (!url) {
    return null;
  }
  if (!url.includes('cards.scryfall.io')) {
    return url;
  }
  if (variant === 'detail' && url.includes('/normal/')) {
    return url
      .replace('/normal/', '/png/')
      .replace(/\.(jpg|jpeg)$/i, '.png');
  }
  if (url.includes('/normal/')) {
    return url.replace('/normal/', '/large/');
  }
  return url;
}
