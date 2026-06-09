import '../l10n/app_localizations.dart';
import '../models/deck.dart';

class DeckValidationResult {
  DeckValidationResult({
    required this.isFormatValid,
    required this.isFullyAssigned,
    required this.formatMessages,
    required this.assignmentMessages,
  });

  final bool isFormatValid;
  final bool isFullyAssigned;
  final List<String> formatMessages;
  final List<String> assignmentMessages;

  List<String> get allMessages => [...formatMessages, ...assignmentMessages];
}

int totalUnfilledCopies(DeckDetails deck) =>
    deck.cards.fold<int>(0, (sum, c) => sum + c.fillStatus.unfilledQty);

int countCardsNotInCollection(DeckDetails deck) =>
    deck.cards.where((c) => !c.inCollection).length;

bool isDeckFullyAssigned(DeckDetails deck) {
  final inCollection = deck.cards.where((c) => c.inCollection).toList();
  if (inCollection.isEmpty) return false;
  return inCollection.every((c) => c.fillStatus.unfilledQty <= 0);
}

List<String> _collectFormatMessages(DeckDetails deck, AppLocalizations l10n) {
  final messages = <String>[];
  final format = deck.format;
  final mainCards = deck.cards.where((c) => c.board == 'main').toList();
  final totalMain = mainCards.fold<int>(0, (sum, c) => sum + c.quantity);

  if (format == 'Standard' || format == 'Modern' || format == 'Pioneer') {
    if (totalMain < 60) {
      messages.add(l10n.deckValidatorMainMin60(totalMain));
    }
    _checkCopyLimits(mainCards, 4, messages, l10n);
  } else if (format == 'Commander') {
    if (totalMain < 100) {
      messages.add(l10n.deckValidatorCommanderMin100(totalMain));
    }
    _checkCopyLimits(mainCards, 1, messages, l10n, excludeType: 'Basic Land');
  }

  final warnings = deck.cards.where((c) => c.formatWarning != null).length;
  if (warnings > 0) {
    messages.add(l10n.deckValidatorLegalityWarnings(warnings));
  }

  return messages;
}

List<String> _collectAssignmentMessages(DeckDetails deck, AppLocalizations l10n) {
  final messages = <String>[];
  final unfilledInCollection = deck.cards
      .where((c) => c.inCollection && c.fillStatus.unfilledQty > 0)
      .toList();
  if (unfilledInCollection.isNotEmpty) {
    final unfilledCopies = unfilledInCollection.fold<int>(
      0,
      (sum, c) => sum + c.fillStatus.unfilledQty,
    );
    messages.add(
      l10n.deckValidatorUnfilledPositions(
        unfilledInCollection.length,
        unfilledCopies,
      ),
    );
  }

  final notInCollection = countCardsNotInCollection(deck);
  if (notInCollection > 0) {
    messages.add(l10n.deckValidatorNotInCollection(notInCollection));
  }

  return messages;
}

DeckValidationResult validateDeck(DeckDetails deck, AppLocalizations l10n) {
  final formatMessages = _collectFormatMessages(deck, l10n);
  final assignmentMessages = _collectAssignmentMessages(deck, l10n);

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
  List<String> messages,
  AppLocalizations l10n, {
  String? excludeType,
}) {
  final counts = <String, int>{};
  for (final card in cards) {
    counts[card.scryfallId] = (counts[card.scryfallId] ?? 0) + card.quantity;
  }
  for (final entry in counts.entries) {
    if (entry.value > maxCopies) {
      messages.add(l10n.deckValidatorCopyLimit(maxCopies, entry.value));
    }
  }
}
