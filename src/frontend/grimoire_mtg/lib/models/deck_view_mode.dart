import 'package:flutter/material.dart';

enum DeckViewMode {
  list,
  grid,
  stack,
}

extension DeckViewModeX on DeckViewMode {
  String get label => switch (this) {
        DeckViewMode.list => 'Lista',
        DeckViewMode.grid => 'Siatka',
        DeckViewMode.stack => 'Stos',
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
