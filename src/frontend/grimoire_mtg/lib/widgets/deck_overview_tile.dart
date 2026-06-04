import 'package:flutter/material.dart';

import '../models/deck.dart';

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
    final validityIcon = deck.isValid == true
        ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
        : deck.isValid == false
            ? Icon(Icons.error_outline, color: Colors.orange.shade700, size: 20)
            : null;

    if (compact) {
      return ListTile(
        leading: const Icon(Icons.style),
        title: Text(deck.name),
        subtitle: Text(deck.format),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (validityIcon != null) validityIcon,
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
                  if (validityIcon != null) validityIcon,
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
