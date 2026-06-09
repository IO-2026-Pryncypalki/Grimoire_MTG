import {
  resolveHiResImageUri,
  scryfallHiResFromStoredNormal,
} from '../src/backend/scanner/scryfallImageUrl';

const normalUrl =
  'https://cards.scryfall.io/normal/front/a/b/abc.jpg';
const largeUrl =
  'https://cards.scryfall.io/large/front/a/b/abc.jpg';
const pngUrl =
  'https://cards.scryfall.io/png/front/a/b/abc.png';

describe('resolveHiResImageUri', () => {
  test('grid prefers large over normal', () => {
    expect(
      resolveHiResImageUri(
        { image_uris: { normal: normalUrl, large: largeUrl, png: pngUrl } },
        'grid',
      ),
    ).toBe(largeUrl);
  });

  test('detail prefers png', () => {
    expect(
      resolveHiResImageUri(
        { image_uris: { normal: normalUrl, large: largeUrl, png: pngUrl } },
        'detail',
      ),
    ).toBe(pngUrl);
  });

  test('uses first card face for DFC', () => {
    expect(
      resolveHiResImageUri(
        {
          card_faces: [
            { image_uris: { normal: normalUrl, large: largeUrl } },
          ],
        },
        'grid',
      ),
    ).toBe(largeUrl);
  });

  test('returns null when no uris', () => {
    expect(resolveHiResImageUri({}, 'grid')).toBeNull();
  });
});

describe('scryfallHiResFromStoredNormal', () => {
  test('grid replaces normal with large on Scryfall CDN', () => {
    expect(scryfallHiResFromStoredNormal(normalUrl, 'grid')).toBe(largeUrl);
  });

  test('detail replaces normal with png on Scryfall CDN', () => {
    expect(
      scryfallHiResFromStoredNormal(normalUrl, 'detail'),
    ).toBe('https://cards.scryfall.io/png/front/a/b/abc.png');
  });

  test('returns url unchanged for non-Scryfall hosts', () => {
    expect(
      scryfallHiResFromStoredNormal('https://example.com/bolt.jpg', 'grid'),
    ).toBe('https://example.com/bolt.jpg');
  });

  test('returns null for null input', () => {
    expect(scryfallHiResFromStoredNormal(null, 'grid')).toBeNull();
  });
});
