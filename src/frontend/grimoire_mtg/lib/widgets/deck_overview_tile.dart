import 'package:flutter/material.dart';

import '../models/deck.dart';
import 'deck_list_status_icons.dart';

class DeckOverviewTile extends StatelessWidget {
  const DeckOverviewTile({
    super.key,
    required this.deck,
    required this.onTap,
    this.compact = false,
  });

  final DeckListItem deck;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusIcons = DeckListStatusIcons(deck: deck);

    if (compact) {
      return ListTile(
        leading: const Icon(Icons.style),
        title: Text(deck.name),
        subtitle: Text(deck.format),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusIcons,
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: onTap,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.style, color: theme.colorScheme.primary, size: 28),
                  const Spacer(),
                  statusIcons,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                deck.name,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                deck.format,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
