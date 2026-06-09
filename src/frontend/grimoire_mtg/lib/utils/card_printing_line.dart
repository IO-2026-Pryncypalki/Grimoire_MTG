import '../models/card.dart';

/// Compact printing label for grid tiles, e.g. `TSR • #333 • 2021`.
String? formatCardPrintingLine(CardDto card) {
  final parts = <String>[];
  if (card.setCode != null && card.setCode!.isNotEmpty) {
    parts.add(card.setCode!.toUpperCase());
  }
  if (card.collectorNumber != null && card.collectorNumber!.isNotEmpty) {
    parts.add('#${card.collectorNumber}');
  }
  final year = card.releasedYear;
  if (year != null) {
    parts.add(year.toString());
  }
  return parts.isEmpty ? null : parts.join(' • ');
}
