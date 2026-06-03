import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/card.dart';

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
    final price = card.price;
    final priceText =
        price != null ? NumberFormat.simpleCurrency().format(price) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: card.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: card.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    )
                  : const ColoredBox(
                      color: Colors.black26,
                      child: Icon(Icons.style, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name ?? 'Unknown',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else if (card.setCode != null)
                    Text(
                      card.setCode!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (priceText != null)
                    Text(
                      priceText,
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
