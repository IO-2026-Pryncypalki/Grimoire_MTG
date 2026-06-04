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
import 'mtg_network_card_image.dart';

class DeckCardsStackView extends StatelessWidget {
  const DeckCardsStackView({
    super.key,
    required this.deck,
    required this.actions,
  });

  final DeckDetails deck;
  final DeckCardActions actions;

  List<Widget> _typeGroupedStacks(List<DeckCardItem> cards) {
    return [
      for (final group in groupDeckCardsByType(cards)) ...[
        DeckTypeSectionHeader(typeLabel: group.label, cards: group.cards),
        _StackRow(cards: group.cards, actions: actions),
        const SizedBox(height: 12),
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
            ..._typeGroupedStacks(cards),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}

class _StackRow extends StatelessWidget {
  const _StackRow({required this.cards, required this.actions});

  final List<DeckCardItem> cards;
  final DeckCardActions actions;

  double _slotWidth(BuildContext context) {
    if (context.isExpanded) return 120;
    if (context.isMediumUp) return 100;
    return 80;
  }

  @override
  Widget build(BuildContext context) {
    final slotWidth = _slotWidth(context);
    final overlap = slotWidth * 0.55;
    final cardHeight = slotWidth / kMtgCardAspectRatio;
    final rowWidth = cards.isEmpty
        ? 0.0
        : slotWidth + (cards.length - 1) * overlap;

    return SizedBox(
      height: cardHeight + 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: rowWidth,
          height: cardHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < cards.length; i++)
                Positioned(
                  left: i * overlap,
                  child: _StackCardSlot(
                    card: cards[i],
                    width: slotWidth,
                    height: cardHeight,
                    actions: actions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackCardSlot extends StatelessWidget {
  const _StackCardSlot({
    required this.card,
    required this.width,
    required this.height,
    required this.actions,
  });

  final DeckCardItem card;
  final double width;
  final double height;
  final DeckCardActions actions;

  @override
  Widget build(BuildContext context) {
    final name = card.name ?? card.scryfallId;
    final semanticsLabel =
        '${card.quantity}x $name, ${card.fillStatus.filledQty}/${card.fillStatus.quantity} przypisane';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => actions.onOpenDetail(card),
          onLongPress: () => actions.showContextMenu(context, card),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: Colors.black12,
                  child: card.imageUrl != null
                      ? MtgNetworkCardImage(
                          imageUrl: card.imageUrl,
                          imageUrlHiRes: card.imageUrlHiRes,
                          tier: CardImageTier.grid,
                          fit: BoxFit.contain,
                        )
                      : const Center(child: Icon(Icons.style, size: 32)),
                ),
                if (card.quantity > 1)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '×${card.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (card.formatWarning != null)
                  const Positioned(
                    top: 4,
                    left: 4,
                    child: Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  ),
                if (card.fillStatus.unfilledQty > 0)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
