import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/deck_validator.dart';

class DeckStatusChips extends StatelessWidget {
  const DeckStatusChips({super.key, required this.deck});

  final DeckDetails deck;

  @override
  Widget build(BuildContext context) {
    final validation = validateDeck(deck);
    final formatOk = validation.isFormatValid;
    final assignedOk = validation.isFullyAssigned;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _StatusChip(
          icon: formatOk ? Icons.rule : Icons.rule_folder,
          label: formatOk ? 'Format OK' : 'Format: uwagi',
          color: formatOk ? Colors.green : Colors.orange,
          tooltip: validation.formatMessages.isEmpty
              ? 'Talia spełnia wymagania formatu'
              : validation.formatMessages.join('\n'),
        ),
        _StatusChip(
          icon: assignedOk ? Icons.inventory_2 : Icons.inventory_2_outlined,
          label: assignedOk ? 'Przypisane' : 'Brak przypisań',
          color: assignedOk ? Colors.green : Colors.orange,
          tooltip: validation.assignmentMessages.isEmpty
              ? 'Wszystkie kopie przypisane z kolekcji'
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
