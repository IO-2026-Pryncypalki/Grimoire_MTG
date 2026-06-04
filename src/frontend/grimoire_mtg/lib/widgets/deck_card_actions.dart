import 'package:flutter/material.dart';

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

  List<PopupMenuEntry<String>> menuItems(DeckCardItem card) => [
        if (card.fillStatus.unfilledQty > 0)
          const PopupMenuItem(
            value: 'assign',
            child: Text('Przypisz kopie'),
          ),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Usuń z talii'),
        ),
      ];

  Future<void> handleMenuSelection(String value, DeckCardItem card) async {
    switch (value) {
      case 'assign':
        await onAssign(card);
      case 'remove':
        await onRemove(card);
    }
  }

  Widget menuButton(DeckCardItem card) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => handleMenuSelection(value, card),
      itemBuilder: (ctx) => menuItems(card),
    );
  }

  void showContextMenu(BuildContext context, DeckCardItem card) {
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
                title: const Text('Przypisz kopie'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAssign(card);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Usuń z talii'),
              onTap: () {
                Navigator.pop(ctx);
                onRemove(card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Szczegóły karty'),
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
