import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/responsive.dart';
import '../utils/scryfall_image_url.dart';
import '../utils/deck_card_type_grouping.dart';
import 'deck_board_header.dart';
import 'deck_boards_layout.dart';
import 'deck_card_actions.dart';
import 'deck_detail_meta_header.dart';
import 'deck_type_section_header.dart';
import 'fill_status_indicator.dart';
import 'mtg_network_card_image.dart';

class DeckCardsListView extends StatelessWidget {
  const DeckCardsListView({
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
        DeckDetailMetaHeader(deck: deck),
        DeckBoardsLayout(
          deck: deck,
          buildBoardSection: (context, board, cards) => [
            DeckBoardHeader(board: board, cards: cards),
            ..._typeGroupedTiles(context, cards),
          ],
        ),
      ],
    );
  }

  List<Widget> _typeGroupedTiles(BuildContext context, List<DeckCardItem> cards) {
    final widgets = <Widget>[];
    for (final group in groupDeckCardsByType(cards)) {
      widgets.add(DeckTypeSectionHeader(typeLabel: group.label, cards: group.cards));
      widgets.addAll(_cardTiles(context, group.cards));
    }
    return widgets;
  }

  List<Widget> _cardTiles(BuildContext context, List<DeckCardItem> cards) {
    if (!context.isMediumUp) {
      return cards.map((card) => _listTile(context, card)).toList();
    }

    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final left = _listTile(context, cards[i]);
      if (i + 1 < cards.length) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 8),
              Expanded(child: _listTile(context, cards[i + 1])),
            ],
          ),
        );
      } else {
        rows.add(left);
      }
    }
    return rows;
  }

  Widget _listTile(BuildContext context, DeckCardItem card) {
    final thumbWidth = context.isMediumUp ? 48.0 : 40.0;
    final thumbHeight = thumbWidth * (56 / 40);

    return ListTile(
      onTap: () => actions.onOpenDetail(card),
      contentPadding: context.isMediumUp
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
          : null,
      leading: card.imageUrl != null
          ? SizedBox(
              width: thumbWidth,
              height: thumbHeight,
              child: MtgNetworkCardImage(
                imageUrl: card.imageUrl,
                imageUrlHiRes: card.imageUrlHiRes,
                tier: CardImageTier.thumbnail,
                width: thumbWidth,
                height: thumbHeight,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.style),
      title: Text('${card.quantity}x ${card.name ?? card.scryfallId}'),
      subtitle: card.formatWarning != null
          ? Text(
              card.formatWarning!.message,
              style: const TextStyle(color: Colors.orange),
            )
          : Text(card.setCode ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FillStatusIndicator(fillStatus: card.fillStatus),
          actions.menuButton(card),
        ],
      ),
    );
  }
}
