import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/card_grid.dart';
import '../utils/deck_card_type_grouping.dart';
import 'deck_board_header.dart';
import 'deck_boards_layout.dart';
import 'deck_card_actions.dart';
import 'deck_card_grid_tile.dart';
import 'deck_detail_meta_header.dart';
import 'deck_type_section_header.dart';

class DeckCardsGridView extends StatelessWidget {
  const DeckCardsGridView({
    super.key,
    required this.deck,
    required this.actions,
  });

  final DeckDetails deck;
  final DeckCardActions actions;

  List<Widget> _typeGroupedGrids(BuildContext context, List<DeckCardItem> cards) {
    return [
      for (final group in groupDeckCardsByType(cards)) ...[
        DeckTypeSectionHeader(typeLabel: group.label, cards: group.cards),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: cardGridDelegate(context),
          itemCount: group.cards.length,
          itemBuilder: (context, index) => DeckCardGridTile(
            card: group.cards[index],
            actions: actions,
          ),
        ),
        const SizedBox(height: 4),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DeckDetailMetaHeader(deck: deck),
        DeckBoardsLayout(
          deck: deck,
          buildBoardSection: (context, board, cards) => [
            DeckBoardHeader(board: board, cards: cards),
            ..._typeGroupedGrids(context, cards),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}
