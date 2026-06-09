import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
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
    final l10n = context.l10n;

    if (!inCollection) {
      return Tooltip(
        message: l10n.collectionNotInCollection,
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
      message: l10n.fillStatusAssigned(
        fillStatus.filledQty,
        fillStatus.quantity,
      ),
      child: Chip(
        label: Text(l10n.fillStatusMissing(fillStatus.unfilledQty)),
        backgroundColor: Colors.orange.withValues(alpha: 0.3),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
