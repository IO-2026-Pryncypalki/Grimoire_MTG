import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/models/card.dart';
import 'package:grimoire_mtg/models/scan.dart';

void main() {
  test('CardDto parses JSON', () {
    final card = CardDto.fromJson({
      'scryfallId': '00000000-0000-0000-0000-000000000001',
      'name': 'Lightning Bolt',
      'setCode': 'M21',
      'price': 1.25,
    });
    expect(card.name, 'Lightning Bolt');
    expect(card.price, 1.25);
  });

  test('ScanResponse detects unique resolution', () {
    final scan = ScanResponse.fromJson({
      'resolution': 'unique',
      'cards': [],
      'total': 0,
    });
    expect(scan.isUnique, isTrue);
  });
}
