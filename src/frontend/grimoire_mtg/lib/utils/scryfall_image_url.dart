enum CardImageTier {
  thumbnail,
  grid,
  detail,
}

String? cardImageUrlForDisplay({
  String? imageUrl,
  String? imageUrlHiRes,
  required CardImageTier tier,
}) {
  if (tier == CardImageTier.thumbnail) {
    return imageUrl;
  }
  if (imageUrlHiRes != null && imageUrlHiRes.isNotEmpty) {
    return imageUrlHiRes;
  }
  return _deriveHiResFromNormal(imageUrl, tier);
}

String? _deriveHiResFromNormal(String? url, CardImageTier tier) {
  if (url == null || !url.contains('cards.scryfall.io')) {
    return url;
  }
  if (!url.contains('/normal/')) {
    return url;
  }
  if (tier == CardImageTier.detail) {
    final pngPath = url.replaceFirst('/normal/', '/png/');
    if (pngPath.endsWith('.jpg') || pngPath.endsWith('.jpeg')) {
      return '${pngPath.substring(0, pngPath.lastIndexOf('.'))}.png';
    }
    if (pngPath != url) {
      return pngPath;
    }
    return url.replaceFirst('/normal/', '/large/');
  }
  return url.replaceFirst('/normal/', '/large/');
}
