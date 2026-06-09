import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/deck.dart';
import '../utils/deck_board_layout.dart';

class DeckTypeSectionHeader extends StatelessWidget {
  const DeckTypeSectionHeader({
    super.key,
    required this.typeLabel,
    required this.cards,
  });

  final String typeLabel;
  final List<DeckCardItem> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Text(
            typeLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              deckBoardSummary(cards, l10n),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
