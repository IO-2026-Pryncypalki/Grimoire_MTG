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
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deckBoardLabel(board),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            deckBoardSummary(cards),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
