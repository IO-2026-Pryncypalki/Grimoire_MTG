import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/models/card_search_result.dart';

void main() {
  test('parsuje odpowiedź wyszukiwania z noMatch i didYouMean', () {
    final result = CardSearchResult.fromJson({
      'cards': [
        {
          'scryfallId': '00000000-0000-0000-0000-000000000001',
          'name': 'Lightning Bolt',
          'setCode': 'M21',
          'price': 1.25,
        },
      ],
      'total': 1,
      'noMatch': false,
      'didYouMean': ['Lightning Helix'],
      'searchMode': 'autocomplete',
    });

    expect(result.cards, hasLength(1));
    expect(result.noMatch, isFalse);
    expect(result.didYouMean, ['Lightning Helix']);
    expect(result.searchMode, 'autocomplete');
  });
}
