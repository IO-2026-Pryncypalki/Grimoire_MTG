import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/deck.dart';
import 'fill_status_indicator.dart';

typedef DeckCardCallback = Future<void> Function(DeckCardItem card);
typedef DeckCardTap = void Function(DeckCardItem card);

class DeckCardActions {
  const DeckCardActions({
    required this.onAssign,
    required this.onRemove,
    required this.onOpenDetail,
  });

  final DeckCardCallback onAssign;
  final DeckCardCallback onRemove;
  final DeckCardTap onOpenDetail;

  List<PopupMenuEntry<String>> menuItems(BuildContext context, DeckCardItem card) {
    final l10n = context.l10n;
    return [
      if (card.fillStatus.unfilledQty > 0)
        PopupMenuItem(
          value: 'assign',
          child: Text(l10n.deckAssignCopies),
        ),
      PopupMenuItem(
        value: 'remove',
        child: Text(l10n.deckRemoveFromDeck),
      ),
    ];
  }

  Future<void> handleMenuSelection(String value, DeckCardItem card) async {
    switch (value) {
      case 'assign':
        await onAssign(card);
      case 'remove':
        await onRemove(card);
    }
  }

  Widget menuButton(BuildContext context, DeckCardItem card) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => handleMenuSelection(value, card),
      itemBuilder: (ctx) => menuItems(ctx, card),
    );
  }

  void showContextMenu(BuildContext context, DeckCardItem card) {
    final l10n = context.l10n;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(card.name ?? card.scryfallId),
              subtitle: Text('${card.quantity}x'),
              trailing: FillStatusIndicator(
                fillStatus: card.fillStatus,
                inCollection: card.inCollection,
              ),
            ),
            if (card.fillStatus.unfilledQty > 0)
              ListTile(
                leading: const Icon(Icons.link),
                title: Text(l10n.deckAssignCopies),
                onTap: () {
                  Navigator.pop(ctx);
                  onAssign(card);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deckRemoveFromDeck),
              onTap: () {
                Navigator.pop(ctx);
                onRemove(card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.deckCardDetails),
              onTap: () {
                Navigator.pop(ctx);
                onOpenDetail(card);
              },
            ),
          ],
        ),
      ),
    );
  }
}
