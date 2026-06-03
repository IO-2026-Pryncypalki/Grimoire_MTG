import 'package:flutter/material.dart';

import '../models/deck.dart';

class FillStatusIndicator extends StatelessWidget {
  const FillStatusIndicator({super.key, required this.fillStatus});

  final FillStatusDto fillStatus;

  @override
  Widget build(BuildContext context) {
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
