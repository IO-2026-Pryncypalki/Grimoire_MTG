import 'package:flutter/material.dart';

import '../models/deck.dart';

class FillStatusIndicator extends StatelessWidget {
  const FillStatusIndicator({
    super.key,
    required this.fillStatus,
    required this.inCollection,
  });

  final FillStatusDto fillStatus;
  final bool inCollection;

  @override
  Widget build(BuildContext context) {
    if (!inCollection) {
      return Tooltip(
        message: 'Brak w kolekcji',
        child: Icon(
          Icons.inventory_2_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      );
    }

    if (fillStatus.unfilledQty <= 0) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    return Tooltip(
      message:
          'Przypisano ${fillStatus.filledQty}/${fillStatus.quantity} kopii',
      child: Chip(
        label: Text('${fillStatus.unfilledQty} brak'),
        backgroundColor: Colors.orange.withValues(alpha: 0.3),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
