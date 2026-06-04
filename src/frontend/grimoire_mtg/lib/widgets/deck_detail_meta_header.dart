import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/deck_validator.dart';
import '../utils/responsive.dart';
import 'deck_status_chips.dart';

class DeckDetailMetaHeader extends StatelessWidget {
  const DeckDetailMetaHeader({super.key, required this.deck});

  final DeckDetails deck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCopies = deck.cards.fold<int>(0, (sum, c) => sum + c.quantity);
    final filledCopies = deck.cards.fold<int>(
      0,
      (sum, c) => sum + c.fillStatus.filledQty,
    );
    final unfilledCopies = totalUnfilledCopies(deck);

    final formatLine = Text(
      deck.format,
      style: theme.textTheme.titleSmall,
    );
    final statsLine = Text(
      '${deck.cards.length} pozycji • $totalCopies kopii • $filledCopies przypisane'
      '${unfilledCopies > 0 ? ' • $unfilledCopies brak' : ''}',
      style: theme.textTheme.bodyMedium,
    );
    final statusChips = DeckStatusChips(deck: deck);

    if (context.isMediumUp) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.style,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deck.description != null && deck.description!.isNotEmpty)
                      Text(
                        deck.description!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    if (deck.description != null && deck.description!.isNotEmpty)
                      const SizedBox(height: 8),
                    formatLine,
                    const SizedBox(height: 4),
                    statsLine,
                    const SizedBox(height: 8),
                    statusChips,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        formatLine,
        const SizedBox(height: 4),
        statsLine,
        if (deck.description != null) ...[
          const SizedBox(height: 8),
          Text(deck.description!),
        ],
        const SizedBox(height: 8),
        statusChips,
        const SizedBox(height: 8),
      ],
    );
  }
}
