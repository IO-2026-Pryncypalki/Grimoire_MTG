import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/scryfall_image_url.dart';

/// Scryfall card aspect ratio (488×680 normal; png uses the same ratio).
const kMtgCardAspectRatio = 488 / 680;

class MtgNetworkCardImage extends StatefulWidget {
  const MtgNetworkCardImage({
    super.key,
    this.imageUrl,
    this.imageUrlHiRes,
    required this.tier,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final String? imageUrlHiRes;
  final CardImageTier tier;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<MtgNetworkCardImage> createState() => _MtgNetworkCardImageState();
}

class _MtgNetworkCardImageState extends State<MtgNetworkCardImage> {
  bool _useFallbackUrl = false;

  @override
  void didUpdateWidget(MtgNetworkCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.imageUrlHiRes != widget.imageUrlHiRes ||
        oldWidget.tier != widget.tier) {
      _useFallbackUrl = false;
    }
  }

  String? _resolvedUrl() {
    if (_useFallbackUrl &&
        widget.tier == CardImageTier.detail &&
        widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty) {
      return widget.imageUrl;
    }
    return cardImageUrlForDisplay(
      imageUrl: widget.imageUrl,
      imageUrlHiRes: widget.imageUrlHiRes,
      tier: widget.tier,
    );
  }

  bool _canFallbackOnError(String failedUrl) {
    return widget.tier == CardImageTier.detail &&
        !_useFallbackUrl &&
        widget.imageUrl != null &&
        widget.imageUrl!.isNotEmpty &&
        failedUrl != widget.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedUrl();

    if (resolved == null) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      key: ValueKey(resolved),
      imageUrl: resolved,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      filterQuality: FilterQuality.high,
      placeholder: (context, url) =>
          widget.placeholder ??
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) {
        if (_canFallbackOnError(url)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _useFallbackUrl = true);
            }
          });
          return widget.placeholder ??
              const Center(child: CircularProgressIndicator());
        }
        return widget.errorWidget ?? const Icon(Icons.broken_image);
      },
    );
  }
}
