import 'package:flutter/material.dart';

import '../widgets/mtg_card_tile.dart';
import 'responsive.dart';

/// Grid cell width/height ratio accounting for image + text footer.
double cardGridMaxExtent(BuildContext context) {
  if (context.isCompact) return 160;
  if (context.isExpanded) return 220;
  return 200;
}

double cardGridChildAspectRatio(BuildContext context) {
  final refWidth = cardGridMaxExtent(context).toDouble();
  // Footer: padding + up to 3 text lines (name, subtitle/set, price).
  const footerHeight = 72.0;
  final refHeight = refWidth / kMtgCardAspectRatio + footerHeight;
  return refWidth / refHeight;
}

SliverGridDelegate cardGridDelegate(BuildContext context) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: cardGridMaxExtent(context),
      childAspectRatio: cardGridChildAspectRatio(context),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    );
