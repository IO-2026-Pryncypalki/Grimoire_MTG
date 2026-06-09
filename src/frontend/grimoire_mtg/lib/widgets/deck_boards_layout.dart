import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/deck.dart';
import '../utils/deck_board_layout.dart';

/// Stacks non-empty deck boards vertically (main, sideboard, commander).
class DeckBoardsLayout extends StatelessWidget {
  const DeckBoardsLayout({
    super.key,
    required this.deck,
    required this.buildBoardSection,
  });

  final DeckDetails deck;
  final List<Widget> Function(
    BuildContext context,
    String board,
    List<DeckCardItem> cards,
  ) buildBoardSection;

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<String, List<DeckCardItem>>>[];
    for (final board in deckBoards) {
      final cards = sortedCardsForBoard(deck, board);
      if (cards.isNotEmpty) {
        entries.add(MapEntry(board, cards));
      }
    }

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text(context.l10n.deckEmptyCards)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildBoardSection(context, entries[i].key, entries[i].value),
          ),
          if (i < entries.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
