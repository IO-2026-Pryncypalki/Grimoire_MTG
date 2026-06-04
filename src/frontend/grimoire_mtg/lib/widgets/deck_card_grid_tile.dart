import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/deck.dart';
import 'deck_card_actions.dart';
import 'fill_status_indicator.dart';

class DeckCardGridTile extends StatelessWidget {
  const DeckCardGridTile({
    super.key,
    required this.card,
    required this.actions,
  });

  final DeckCardItem card;
  final DeckCardActions actions;

  @override
  Widget build(BuildContext context) {
    final name = card.name ?? card.scryfallId;
    final semanticsLabel =
        '${card.quantity}x $name, ${card.fillStatus.filledQty}/${card.fillStatus.quantity} przypisane';

    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => actions.onOpenDetail(card),
          onLongPress: () => actions.showContextMenu(context, card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black12,
                child: card.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: card.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image),
                      )
                    : const Center(child: Icon(Icons.style, size: 48)),
              ),
              if (card.fillStatus.unfilledQty > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: Colors.orange,
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      iconTheme: const IconThemeData(color: Colors.white),
                    ),
                    child: actions.menuButton(card),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '×${card.quantity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (card.formatWarning != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Tooltip(
                    message: card.formatWarning!.message,
                    child: const Icon(
                      Icons.warning_amber,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                ),
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    FillStatusIndicator(fillStatus: card.fillStatus),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
