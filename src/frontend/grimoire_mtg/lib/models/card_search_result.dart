import 'card.dart';

class CardSearchResult {
  CardSearchResult({
    required this.cards,
    required this.total,
    required this.noMatch,
    this.didYouMean = const [],
    this.searchMode = 'direct',
  });

  final List<CardDto> cards;
  final int total;
  final bool noMatch;
  final List<String> didYouMean;
  final String searchMode;

  factory CardSearchResult.fromJson(Map<String, dynamic> json) => CardSearchResult(
        cards: (json['cards'] as List<dynamic>? ?? [])
            .map((e) => CardDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int? ?? 0,
        noMatch: json['noMatch'] as bool? ?? false,
        didYouMean: (json['didYouMean'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        searchMode: json['searchMode'] as String? ?? 'direct',
      );
}
