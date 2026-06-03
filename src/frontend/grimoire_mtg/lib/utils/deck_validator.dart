import '../models/deck.dart';

class DeckValidationResult {
  DeckValidationResult({required this.isValid, required this.messages});

  final bool isValid;
  final List<String> messages;
}

DeckValidationResult validateDeck(DeckDetails deck) {
  final messages = <String>[];
  final format = deck.format;
  final mainCards = deck.cards.where((c) => c.board == 'main').toList();
  final totalMain = mainCards.fold<int>(0, (sum, c) => sum + c.quantity);

  if (format == 'Standard' || format == 'Modern' || format == 'Pioneer') {
    if (totalMain < 60) messages.add('Main deck wymaga min. 60 kart (masz $totalMain).');
    _checkCopyLimits(mainCards, 4, messages);
  } else if (format == 'Commander') {
    if (totalMain < 100) messages.add('Commander wymaga 100 kart (masz $totalMain).');
    _checkCopyLimits(mainCards, 1, messages, excludeType: 'Basic Land');
  }

  final warnings = deck.cards.where((c) => c.formatWarning != null).length;
  if (warnings > 0) {
    messages.add('$warnings kart z ostrzeżeniem legalności.');
  }

  final unfilled = deck.cards.where((c) => c.fillStatus.unfilledQty > 0).length;
  if (unfilled > 0) {
    messages.add('$unfilled slotów bez przypisanych kopii.');
  }

  return DeckValidationResult(
    isValid: messages.where((m) => !m.contains('ostrzeżeniem') && !m.contains('bez przypisanych')).isEmpty,
    messages: messages,
  );
}

void _checkCopyLimits(
  List<DeckCardItem> cards,
  int maxCopies,
  List<String> messages, {
  String? excludeType,
}) {
  final counts = <String, int>{};
  for (final card in cards) {
    counts[card.scryfallId] = (counts[card.scryfallId] ?? 0) + card.quantity;
  }
  for (final entry in counts.entries) {
    if (entry.value > maxCopies) {
      messages.add('Karta przekracza limit $maxCopies kopii ($maxCopies dozwolone, ${entry.value} w decku).');
    }
  }
}
