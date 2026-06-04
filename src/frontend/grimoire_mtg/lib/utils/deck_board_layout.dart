import '../models/deck.dart';

String deckBoardLabel(String board) => switch (board) {
      'main' => 'Główna',
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

String deckBoardSummary(List<DeckCardItem> cards) {
  if (cards.isEmpty) return '0 kart';
  final positions = cards.length;
  final copies = cards.fold<int>(0, (sum, c) => sum + c.quantity);
  final filled = cards.fold<int>(0, (sum, c) => sum + c.fillStatus.filledQty);
  return '$positions poz. • $copies kopii • $filled/$copies przypisane';
}
