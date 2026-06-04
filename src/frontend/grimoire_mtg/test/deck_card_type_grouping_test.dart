import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/models/deck.dart';
import 'package:grimoire_mtg/utils/deck_card_type_grouping.dart';

DeckCardItem _card(String name, String? typeLine) => DeckCardItem(
      id: name,
      scryfallId: name,
      quantity: 1,
      board: 'main',
      name: name,
      typeLine: typeLine,
      inCollection: true,
      fillStatus: FillStatusDto(
        quantity: 1,
        filledQty: 0,
        unfilledQty: 1,
        assignments: [],
      ),
    );

void main() {
  test('deckCardTypeCategory rozpoznaje typy ze Scryfall', () {
    expect(deckCardTypeCategory('Instant'), 'Instants');
    expect(deckCardTypeCategory('Creature — Human Wizard'), 'Creatures');
    expect(deckCardTypeCategory('Artifact Creature — Golem'), 'Creatures');
    expect(deckCardTypeCategory('Basic Land — Island'), 'Lands');
    expect(deckCardTypeCategory(null), 'Other');
  });

  test('groupDeckCardsByType sortuje sekcje i nazwy', () {
    final groups = groupDeckCardsByType([
      _card('Bolt', 'Instant'),
      _card('Goyf', 'Creature — Lhurgoyf'),
      _card('Island', 'Basic Land — Island'),
      _card('Bolt2', 'Instant'),
    ]);

    expect(groups.map((g) => g.label).toList(), ['Creatures', 'Instants', 'Lands']);
    expect(groups[1].cards.map((c) => c.name).toList(), ['Bolt', 'Bolt2']);
  });
}
