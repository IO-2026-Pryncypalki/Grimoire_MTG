import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum DeckViewMode {
  list,
  grid,
  stack,
}

extension DeckViewModeX on DeckViewMode {
  String label(AppLocalizations l10n) => switch (this) {
        DeckViewMode.list => l10n.deckViewList,
        DeckViewMode.grid => l10n.deckViewGrid,
        DeckViewMode.stack => l10n.deckViewStack,
      };

  IconData get icon => switch (this) {
        DeckViewMode.list => Icons.view_list,
        DeckViewMode.grid => Icons.grid_view,
        DeckViewMode.stack => Icons.layers,
      };

  static DeckViewMode fromName(String? name) {
    return DeckViewMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => DeckViewMode.list,
    );
  }
}
