import '../models/card.dart';
import '../models/collection.dart';

class GroupedCollectionCard {
  GroupedCollectionCard({
    required this.card,
    required this.entries,
  });

  final CardDto card;
  final List<CollectionEntryDto> entries;

  int get totalQuantity => entries.fold(0, (sum, e) => sum + e.quantity);

  String get subtitleSummary {
    final parts = entries.map((e) {
      final foil = e.isFoil ? '✨' : '';
      return '${e.condition}$foil×${e.quantity}';
    });
    return 'x$totalQuantity • ${parts.join(', ')}';
  }
}

List<GroupedCollectionCard> groupCollectionEntries(List<CollectionEntryDto> entries) {
  final byScryfall = <String, List<CollectionEntryDto>>{};
  for (final entry in entries) {
    byScryfall.putIfAbsent(entry.scryfallId, () => []).add(entry);
  }

  final grouped = byScryfall.values
      .map((group) => GroupedCollectionCard(
            card: group.first.toCardDto(),
            entries: group,
          ))
      .toList();

  grouped.sort(
    (a, b) => (a.card.name ?? a.card.scryfallId)
        .toLowerCase()
        .compareTo((b.card.name ?? b.card.scryfallId).toLowerCase()),
  );
  return grouped;
}
