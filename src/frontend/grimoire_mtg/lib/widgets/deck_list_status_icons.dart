import 'package:flutter/material.dart';

import '../models/deck.dart';

class DeckListStatusIcons extends StatelessWidget {
  const DeckListStatusIcons({super.key, required this.deck});

  final DeckListItem deck;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: deck.isFormatValid
              ? 'Format OK'
              : 'Format: uwagi',
          child: Icon(
            deck.isFormatValid ? Icons.rule : Icons.rule_folder,
            color: deck.isFormatValid ? Colors.green.shade600 : Colors.orange.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: deck.isFullyAssigned
              ? 'Wszystkie kopie z kolekcji przypisane'
              : 'Brak pełnych przypisań',
          child: Icon(
            deck.isFullyAssigned ? Icons.inventory_2 : Icons.inventory_2_outlined,
            color: deck.isFullyAssigned ? Colors.green.shade600 : Colors.orange.shade700,
            size: 20,
          ),
        ),
      ],
    );
  }
}
