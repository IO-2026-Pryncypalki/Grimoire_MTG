import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/card_grid.dart';
import '../utils/deck_board_layout.dart';
import 'deck_board_header.dart';
import 'deck_card_actions.dart';
import 'deck_card_grid_tile.dart';

class DeckCardsGridView extends StatelessWidget {
  const DeckCardsGridView({
    super.key,
    required this.deck,
    required this.actions,
  });

  final DeckDetails deck;
  final DeckCardActions actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('${deck.format} • ${deck.cards.length} pozycji'),
        if (deck.description != null) Text(deck.description!),
        for (final board in deckBoards) ..._boardSection(context, board),
      ],
    );
  }

  List<Widget> _boardSection(BuildContext context, String board) {
    final cards = sortedCardsForBoard(deck, board);
    if (cards.isEmpty) return [];

    return [
      DeckBoardHeader(board: board, cards: cards),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: cardGridDelegate(context),
        itemCount: cards.length,
        itemBuilder: (context, index) => DeckCardGridTile(
          card: cards[index],
          actions: actions,
        ),
      ),
      const SizedBox(height: 8),
    ];
  }
}
