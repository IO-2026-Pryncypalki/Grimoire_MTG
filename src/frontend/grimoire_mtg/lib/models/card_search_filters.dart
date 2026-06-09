import 'package:flutter/foundation.dart';

class CardSearchFilters {
  const CardSearchFilters({
    this.colors = const {},
    this.exactColors = false,
    this.type,
    this.cmc,
    this.rarity,
  });

  final Set<String> colors;

  /// When true, uses `c=WU` (exactly these colors). When false, uses `c:WU`
  /// (contains these colors, possibly with others).
  final bool exactColors;

  final String? type;
  final int? cmc;
  final String? rarity;

  bool get isEmpty =>
      colors.isEmpty && type == null && cmc == null && rarity == null;

  int get activeCount =>
      (colors.isNotEmpty ? 1 : 0) +
      (type != null ? 1 : 0) +
      (cmc != null ? 1 : 0) +
      (rarity != null ? 1 : 0);

  String toScryfallQuery() {
    final parts = <String>[];
    if (colors.isNotEmpty) {
      if (exactColors && colors.length >= 2) {
        // Sort for deterministic query strings (Scryfall order is WUBRG).
        const order = ['W', 'U', 'B', 'R', 'G', 'C'];
        final sorted = [...colors]..sort(
            (a, b) => order.indexOf(a).compareTo(order.indexOf(b)),
          );
        parts.add('c=${sorted.join('')}');
      } else if (colors.length == 1) {
        parts.add('c:${colors.first}');
      } else {
        // OR: cards that include any of the selected colors.
        final joined = colors.map((c) => 'c:$c').join(' or ');
        parts.add('($joined)');
      }
    }
    if (type != null) parts.add('t:$type');
    if (cmc != null) parts.add('cmc=$cmc');
    if (rarity != null) parts.add('r:$rarity');
    return parts.join(' ');
  }

  CardSearchFilters copyWith({
    Set<String>? colors,
    bool? exactColors,
    Object? type = _sentinel,
    Object? cmc = _sentinel,
    Object? rarity = _sentinel,
  }) {
    return CardSearchFilters(
      colors: colors ?? this.colors,
      exactColors: exactColors ?? this.exactColors,
      type: identical(type, _sentinel) ? this.type : type as String?,
      cmc: identical(cmc, _sentinel) ? this.cmc : cmc as int?,
      rarity: identical(rarity, _sentinel) ? this.rarity : rarity as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CardSearchFilters) return false;
    return setEquals(colors, other.colors) &&
        exactColors == other.exactColors &&
        type == other.type &&
        cmc == other.cmc &&
        rarity == other.rarity;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(colors),
        exactColors,
        type,
        cmc,
        rarity,
      );
}

const _sentinel = Object();
