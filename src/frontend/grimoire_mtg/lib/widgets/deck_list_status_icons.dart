import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/deck.dart';

class DeckListStatusIcons extends StatelessWidget {
  const DeckListStatusIcons({super.key, required this.deck});

  final DeckListItem deck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: deck.isFormatValid ? l10n.deckFormatOk : l10n.deckFormatWarnings,
          child: Icon(
            deck.isFormatValid ? Icons.rule : Icons.rule_folder,
            color: deck.isFormatValid ? Colors.green.shade600 : Colors.orange.shade700,
            size: 20,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: deck.isFullyAssigned
              ? l10n.deckListAllAssigned
              : l10n.deckListMissingAssignments,
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
