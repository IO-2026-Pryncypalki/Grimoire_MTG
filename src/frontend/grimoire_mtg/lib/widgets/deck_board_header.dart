import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/deck_board_layout.dart';

class DeckBoardHeader extends StatelessWidget {
  const DeckBoardHeader({
    super.key,
    required this.board,
    required this.cards,
  });

  final String board;
  final List<DeckCardItem> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deckBoardLabel(board),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                deckBoardSummary(cards),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
