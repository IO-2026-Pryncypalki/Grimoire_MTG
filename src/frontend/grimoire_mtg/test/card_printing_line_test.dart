import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/models/card.dart';
import 'package:grimoire_mtg/utils/card_printing_line.dart';

void main() {
  test('formatCardPrintingLine includes set, number, and year', () {
    final card = CardDto(
      scryfallId: 'abc',
      setCode: 'tsr',
      collectorNumber: '333',
      releasedAt: '2021-03-19',
    );

    expect(formatCardPrintingLine(card), 'TSR • #333 • 2021');
  });

  test('formatCardPrintingLine omits missing fields', () {
    final card = CardDto(
      scryfallId: 'abc',
      setCode: 'm21',
    );

    expect(formatCardPrintingLine(card), 'M21');
  });
}
