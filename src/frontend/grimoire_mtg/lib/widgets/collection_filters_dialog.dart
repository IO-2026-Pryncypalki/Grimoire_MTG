import 'package:flutter/material.dart';

import '../models/collection.dart';

/// Shows collection filter dialog. Returns `null` if cancelled, otherwise the
/// chosen filters (empty [CollectionFilters] when cleared).
Future<CollectionFilters?> showCollectionFiltersDialog(
  BuildContext context, {
  CollectionFilters? initial,
}) async {
  final filters = initial ?? CollectionFilters();
  final colorCtrl = TextEditingController(text: filters.color ?? '');
  final typeCtrl = TextEditingController(text: filters.type ?? '');
  final editionCtrl = TextEditingController(text: filters.edition ?? '');
  final cmcCtrl = TextEditingController(
    text: filters.cmc?.toString() ?? '',
  );

  return showDialog<CollectionFilters>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Filtry kolekcji'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: colorCtrl,
              decoration: const InputDecoration(
                labelText: 'Kolor (R, U, G, B, W)',
              ),
            ),
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                labelText: 'Typ (Creature, Instant, ...)',
              ),
            ),
            TextField(
              controller: editionCtrl,
              decoration: const InputDecoration(labelText: 'Edycja / set'),
            ),
            TextField(
              controller: cmcCtrl,
              decoration: const InputDecoration(labelText: 'CMC'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, CollectionFilters()),
          child: const Text('Wyczyść'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              ctx,
              CollectionFilters(
                color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
                type: typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
                edition: editionCtrl.text.trim().isEmpty ? null : editionCtrl.text.trim(),
                cmc: int.tryParse(cmcCtrl.text.trim()),
              ),
            );
          },
          child: const Text('Zastosuj'),
        ),
      ],
    ),
  );
}

extension CollectionFiltersX on CollectionFilters {
  bool get hasActiveFilters =>
      (color != null && color!.isNotEmpty) ||
      (type != null && type!.isNotEmpty) ||
      (edition != null && edition!.isNotEmpty) ||
      cmc != null;

  String get summary {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) parts.add('kolor: $color');
    if (type != null && type!.isNotEmpty) parts.add('typ: $type');
    if (edition != null && edition!.isNotEmpty) parts.add('edycja: $edition');
    if (cmc != null) parts.add('CMC: $cmc');
    return parts.join(' • ');
  }
}
