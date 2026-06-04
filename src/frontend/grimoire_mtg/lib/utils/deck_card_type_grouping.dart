import '../models/deck.dart';

class DeckCardTypeGroup {
  const DeckCardTypeGroup({required this.label, required this.cards});

  final String label;
  final List<DeckCardItem> cards;
}

/// Standard decklist section order (creatures before instants, lands last).
const _typeCategoryOrder = [
  'Planeswalkers',
  'Creatures',
  'Instants',
  'Sorceries',
  'Battles',
  'Enchantments',
  'Artifacts',
  'Lands',
  'Other',
];

/// Maps Scryfall `type_line` to a decklist section label.
String deckCardTypeCategory(String? typeLine) {
  if (typeLine == null || typeLine.trim().isEmpty) {
    return 'Other';
  }

  final lower = typeLine.toLowerCase();

  if (lower.contains('land')) return 'Lands';
  if (lower.contains('creature')) return 'Creatures';
  if (lower.contains('planeswalker')) return 'Planeswalkers';
  if (lower.contains('battle')) return 'Battles';
  if (lower.contains('instant')) return 'Instants';
  if (lower.contains('sorcery')) return 'Sorceries';
  if (lower.contains('enchantment')) return 'Enchantments';
  if (lower.contains('artifact')) return 'Artifacts';

  return 'Other';
}

int _categorySortIndex(String category) {
  final index = _typeCategoryOrder.indexOf(category);
  return index >= 0 ? index : _typeCategoryOrder.length;
}

List<DeckCardTypeGroup> groupDeckCardsByType(List<DeckCardItem> cards) {
  final buckets = <String, List<DeckCardItem>>{};

  for (final card in cards) {
    final category = deckCardTypeCategory(card.typeLine);
    buckets.putIfAbsent(category, () => []).add(card);
  }

  for (final list in buckets.values) {
    list.sort((a, b) {
      final nameA = (a.name ?? a.scryfallId).toLowerCase();
      final nameB = (b.name ?? b.scryfallId).toLowerCase();
      return nameA.compareTo(nameB);
    });
  }

  final categories = buckets.keys.toList()
    ..sort((a, b) {
      final byOrder = _categorySortIndex(a).compareTo(_categorySortIndex(b));
      if (byOrder != 0) return byOrder;
      return a.compareTo(b);
    });

  return [
    for (final category in categories)
      DeckCardTypeGroup(label: category, cards: buckets[category]!),
  ];
}
