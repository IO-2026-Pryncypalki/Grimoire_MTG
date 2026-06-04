import '../models/deck.dart';

class DeckValidationResult {
  DeckValidationResult({
    required this.isFormatValid,
    required this.isFullyAssigned,
    required this.formatMessages,
    required this.assignmentMessages,
  });

  /// Zgodność z regułami formatu (liczba kart, limity kopii, legalność).
  final bool isFormatValid;

  /// Wszystkie kopie w talii mają przypisanie z kolekcji (`unfilledQty == 0`).
  final bool isFullyAssigned;

  final List<String> formatMessages;
  final List<String> assignmentMessages;

  List<String> get allMessages => [...formatMessages, ...assignmentMessages];
}

int totalUnfilledCopies(DeckDetails deck) =>
    deck.cards.fold<int>(0, (sum, c) => sum + c.fillStatus.unfilledQty);

int countCardsNotInCollection(DeckDetails deck) =>
    deck.cards.where((c) => !c.inCollection).length;

/// Wszystkie sloty mają przypisane fizyczne kopie (niezależnie od formatu).
bool isDeckFullyAssigned(DeckDetails deck) {
  if (deck.cards.isEmpty) return false;
  return totalUnfilledCopies(deck) == 0;
}

List<String> _collectFormatMessages(DeckDetails deck) {
  final messages = <String>[];
  final format = deck.format;
  final mainCards = deck.cards.where((c) => c.board == 'main').toList();
  final totalMain = mainCards.fold<int>(0, (sum, c) => sum + c.quantity);

  if (format == 'Standard' || format == 'Modern' || format == 'Pioneer') {
    if (totalMain < 60) {
      messages.add('Main deck wymaga min. 60 kart (masz $totalMain).');
    }
    _checkCopyLimits(mainCards, 4, messages);
  } else if (format == 'Commander') {
    if (totalMain < 100) {
      messages.add('Commander wymaga 100 kart (masz $totalMain).');
    }
    _checkCopyLimits(mainCards, 1, messages, excludeType: 'Basic Land');
  }

  final warnings = deck.cards.where((c) => c.formatWarning != null).length;
  if (warnings > 0) {
    messages.add('$warnings kart z ostrzeżeniem legalności.');
  }

  return messages;
}

List<String> _collectAssignmentMessages(DeckDetails deck) {
  final messages = <String>[];
  final unfilledCopies = totalUnfilledCopies(deck);
  if (unfilledCopies > 0) {
    final unfilledSlots =
        deck.cards.where((c) => c.fillStatus.unfilledQty > 0).length;
    messages.add(
      '$unfilledSlots pozycji bez pełnego przypisania ($unfilledCopies kopii).',
    );
  }

  final notInCollection = countCardsNotInCollection(deck);
  if (notInCollection > 0) {
    messages.add('$notInCollection pozycji bez karty w kolekcji.');
  }

  return messages;
}

DeckValidationResult validateDeck(DeckDetails deck) {
  final formatMessages = _collectFormatMessages(deck);
  final assignmentMessages = _collectAssignmentMessages(deck);

  return DeckValidationResult(
    isFormatValid: formatMessages.isEmpty,
    isFullyAssigned: isDeckFullyAssigned(deck),
    formatMessages: formatMessages,
    assignmentMessages: assignmentMessages,
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
      messages.add(
        'Karta przekracza limit $maxCopies kopii ($maxCopies dozwolone, ${entry.value} w decku).',
      );
    }
  }
}
