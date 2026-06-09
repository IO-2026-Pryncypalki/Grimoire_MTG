import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../models/deck.dart';
import '../utils/deck_validator.dart';

class DeckStatusChips extends StatelessWidget {
  const DeckStatusChips({super.key, required this.deck});

  final DeckDetails deck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final validation = validateDeck(deck, l10n);
    final formatOk = validation.isFormatValid;
    final assignedOk = validation.isFullyAssigned;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _StatusChip(
          icon: formatOk ? Icons.rule : Icons.rule_folder,
          label: formatOk ? l10n.deckFormatOk : l10n.deckFormatWarnings,
          color: formatOk ? Colors.green : Colors.orange,
          tooltip: validation.formatMessages.isEmpty
              ? l10n.deckFormatValidTooltip
              : validation.formatMessages.join('\n'),
        ),
        _StatusChip(
          icon: assignedOk ? Icons.inventory_2 : Icons.inventory_2_outlined,
          label: assignedOk ? l10n.deckAssigned : l10n.deckNotAssigned,
          color: assignedOk ? Colors.green : Colors.orange,
          tooltip: validation.assignmentMessages.isEmpty
              ? l10n.deckAllCopiesAssigned
              : validation.assignmentMessages.join('\n'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Chip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
