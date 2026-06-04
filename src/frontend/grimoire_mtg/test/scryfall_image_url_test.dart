import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/utils/scryfall_image_url.dart';

void main() {
  const normal =
      'https://cards.scryfall.io/normal/front/a/b/abc.jpg';

  test('thumbnail uses normal url', () {
    expect(
      cardImageUrlForDisplay(
        imageUrl: normal,
        imageUrlHiRes: 'https://cards.scryfall.io/large/front/a/b/abc.jpg',
        tier: CardImageTier.thumbnail,
      ),
      normal,
    );
  });

  test('grid prefers imageUrlHiRes', () {
    const large =
        'https://cards.scryfall.io/large/front/a/b/abc.jpg';
    expect(
      cardImageUrlForDisplay(
        imageUrl: normal,
        imageUrlHiRes: large,
        tier: CardImageTier.grid,
      ),
      large,
    );
  });

  test('detail derives png when hi-res missing', () {
    expect(
      cardImageUrlForDisplay(
        imageUrl: normal,
        tier: CardImageTier.detail,
      ),
      'https://cards.scryfall.io/png/front/a/b/abc.png',
    );
  });
}
