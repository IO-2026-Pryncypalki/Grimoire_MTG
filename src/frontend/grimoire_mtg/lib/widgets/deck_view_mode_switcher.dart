import 'package:flutter/material.dart';

import '../models/deck_view_mode.dart';
import '../utils/responsive.dart';

class DeckViewModeSwitcher extends StatelessWidget {
  const DeckViewModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.inAppBar = false,
  });

  final DeckViewMode mode;
  final ValueChanged<DeckViewMode> onChanged;
  final bool inAppBar;

  @override
  Widget build(BuildContext context) {
    if (context.isMediumUp) {
      return SegmentedButton<DeckViewMode>(
        style: inAppBar
            ? SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )
            : null,
        segments: [
          for (final m in DeckViewMode.values)
            ButtonSegment(
              value: m,
              icon: Icon(m.icon, size: 20),
              label: inAppBar ? null : Text(m.label),
              tooltip: m.label,
            ),
        ],
        selected: {mode},
        onSelectionChanged: (selected) => onChanged(selected.first),
      );
    }

    return PopupMenuButton<DeckViewMode>(
      icon: Icon(mode.icon),
      tooltip: 'Widok: ${mode.label}',
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final m in DeckViewMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(m.icon),
                const SizedBox(width: 12),
                Text(m.label),
                if (m == mode) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 18),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
