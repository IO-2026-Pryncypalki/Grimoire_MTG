import 'package:flutter/material.dart';

import '../widgets/mtg_card_tile.dart';
import 'responsive.dart';

/// Grid cell width/height ratio accounting for image + text footer.
double cardGridChildAspectRatio(BuildContext context) {
  final refWidth = context.isCompact ? 160.0 : 200.0;
  // Footer: padding + up to 3 text lines (name, subtitle/set, price).
  const footerHeight = 72.0;
  final refHeight = refWidth / kMtgCardAspectRatio + footerHeight;
  return refWidth / refHeight;
}

SliverGridDelegate cardGridDelegate(BuildContext context) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: context.isCompact ? 160 : 200,
      childAspectRatio: cardGridChildAspectRatio(context),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    );
