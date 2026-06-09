import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_ext.dart';
import '../models/card.dart';
import '../utils/card_printing_line.dart';
import '../utils/scryfall_image_url.dart';
import 'mtg_network_card_image.dart';

export 'mtg_network_card_image.dart' show kMtgCardAspectRatio;

class MtgCardTile extends StatelessWidget {
  const MtgCardTile({
    super.key,
    required this.card,
    this.onTap,
    this.subtitle,
    this.trailing,
  });

  final CardDto card;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final price = card.price;
    final priceText =
        price != null ? NumberFormat.simpleCurrency(locale: locale).format(price) : null;
    final printingLine = subtitle ?? formatCardPrintingLine(card);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ColoredBox(
                color: Colors.black12,
                child: card.imageUrl != null
                    ? MtgNetworkCardImage(
                        imageUrl: card.imageUrl,
                        imageUrlHiRes: card.imageUrlHiRes,
                        tier: CardImageTier.grid,
                        fit: BoxFit.contain,
                      )
                    : const Center(child: Icon(Icons.style, size: 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name ?? l10n.cardDefaultName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (printingLine != null)
                    Text(
                      printingLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (priceText != null)
                    Text(
                      priceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.greenAccent,
                          ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
