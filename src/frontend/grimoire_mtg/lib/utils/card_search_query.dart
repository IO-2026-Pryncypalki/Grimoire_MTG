import '../models/card_search_filters.dart';

String buildCardSearchQuery(String name, CardSearchFilters filters) {
  final trimmed = name.trim();
  final filterQuery = filters.toScryfallQuery();
  final parts = [
    if (trimmed.isNotEmpty) trimmed,
    if (filterQuery.isNotEmpty) filterQuery,
  ];
  return parts.join(' ');
}
