import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/deck_board_layout.dart';
import 'deck_board_header.dart';
import 'deck_card_actions.dart';
import '../utils/scryfall_image_url.dart';
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
      ...cards.map(
        (card) => ListTile(
          onTap: () => actions.onOpenDetail(card),
          leading: card.imageUrl != null
              ? SizedBox(
                  width: 40,
                  height: 56,
                  child: MtgNetworkCardImage(
                    imageUrl: card.imageUrl,
                    imageUrlHiRes: card.imageUrlHiRes,
                    tier: CardImageTier.thumbnail,
                    width: 40,
                    height: 56,
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
        ),
      ),
    ];
  }
}
