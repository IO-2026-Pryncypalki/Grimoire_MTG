import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/collection.dart';

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
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      return AlertDialog(
        title: Text(l10n.collectionFiltersTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: colorCtrl,
                decoration: InputDecoration(
                  labelText: l10n.collectionFilterColor,
                ),
              ),
              TextField(
                controller: typeCtrl,
                decoration: InputDecoration(
                  labelText: l10n.collectionFilterType,
                ),
              ),
              TextField(
                controller: editionCtrl,
                decoration: InputDecoration(labelText: l10n.collectionFilterEdition),
              ),
              TextField(
                controller: cmcCtrl,
                decoration: InputDecoration(labelText: l10n.collectionFilterCmc),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, CollectionFilters()),
            child: Text(l10n.commonClear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
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
            child: Text(l10n.commonApply),
          ),
        ],
      );
    },
  );
}

extension CollectionFiltersX on CollectionFilters {
  bool get hasActiveFilters =>
      (color != null && color!.isNotEmpty) ||
      (type != null && type!.isNotEmpty) ||
      (edition != null && edition!.isNotEmpty) ||
      cmc != null;

  String summary(AppLocalizations l10n) {
    final parts = <String>[];
    if (color != null && color!.isNotEmpty) {
      parts.add(l10n.collectionFilterSummaryColor(color!));
    }
    if (type != null && type!.isNotEmpty) {
      parts.add(l10n.collectionFilterSummaryType(type!));
    }
    if (edition != null && edition!.isNotEmpty) {
      parts.add(l10n.collectionFilterSummaryEdition(edition!));
    }
    if (cmc != null) parts.add(l10n.collectionFilterSummaryCmc(cmc!));
    return parts.join(' • ');
  }
}
