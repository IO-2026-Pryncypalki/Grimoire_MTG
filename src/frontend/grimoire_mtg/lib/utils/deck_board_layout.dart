import '../l10n/app_localizations.dart';
import '../models/deck.dart';

String deckBoardLabel(String board, AppLocalizations l10n) => switch (board) {
      'main' => l10n.deckBoardMain,
      'sideboard' => 'Sideboard',
      'commander' => 'Commander',
      _ => board,
    };

List<DeckCardItem> sortedCardsForBoard(DeckDetails deck, String board) {
  final cards = deck.cards.where((c) => c.board == board).toList();
  cards.sort((a, b) {
    final nameA = (a.name ?? a.scryfallId).toLowerCase();
    final nameB = (b.name ?? b.scryfallId).toLowerCase();
    return nameA.compareTo(nameB);
  });
  return cards;
}

String deckBoardSummary(List<DeckCardItem> cards, AppLocalizations l10n) {
  if (cards.isEmpty) return l10n.deckBoardEmpty;
  final positions = cards.length;
  final copies = cards.fold<int>(0, (sum, c) => sum + c.quantity);
  final filled = cards.fold<int>(0, (sum, c) => sum + c.fillStatus.filledQty);
  return l10n.deckBoardSummary(positions, copies, filled, copies);
}
