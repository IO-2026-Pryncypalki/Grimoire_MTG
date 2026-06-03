import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../state/deck_detail_store.dart';
import '../state/deck_store.dart';
import '../utils/deck_validator.dart';
import '../widgets/api_error_view.dart';
import '../widgets/fill_status_indicator.dart';
import 'card_search_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = context.read<SyncService>();
    _sync.setActiveDeckId(widget.deckId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<DeckDetailStore>();
      if (store.deckFor(widget.deckId) == null && !store.isLoading(widget.deckId)) {
        store.load(widget.deckId);
      }
    });
  }

  @override
  void dispose() {
    _sync.setActiveDeckId(null);
    super.dispose();
  }

  Future<void> _refreshStores() async {
    await context.read<DeckDetailStore>().refresh(widget.deckId);
    await context.read<DeckStore>().refresh(silent: true);
    await context.read<AuthService>().reloadProfile();
  }

  Future<void> _validateAndSave(DeckDetails deck) async {
    final result = validateDeck(deck);
    try {
      await context.read<AuthService>().api.updateDeck(
            widget.deckId,
            isValid: result.isValid,
            lastValidatedAt: DateTime.now().toUtc().toIso8601String(),
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(result.isValid ? 'Deck poprawny' : 'Problemy w decku'),
            content: result.messages.isEmpty
                ? const Text('Brak uwag.')
                : Text(result.messages.join('\n')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
        await _refreshStores();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteDeck() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć talię?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<AuthService>().api.deleteDeck(widget.deckId);
      await context.read<DeckStore>().refresh(silent: true);
      await context.read<AuthService>().reloadProfile();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _removeCard(DeckCardItem card) async {
    try {
      await context.read<AuthService>().api.removeCardFromDeck(
            deckId: widget.deckId,
            scryfallId: card.scryfallId,
            board: card.board,
          );
      await _refreshStores();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _assignCopies(DeckCardItem card) async {
    final api = context.read<AuthService>().api;
    List<CollectionOptionDto> options;
    try {
      options = await api.getCollectionOptions(
        deckId: widget.deckId,
        deckCardId: card.id,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    if (!mounted) return;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak kopii w kolekcji')),
      );
      return;
    }

    final selected = await showModalBottomSheet<CollectionOptionDto>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Przypisz kopie z kolekcji')),
            ...options.map(
              (o) => ListTile(
                title: Text('${o.condition}${o.isFoil ? ' Foil' : ''}'),
                subtitle: Text('Dostępne: ${o.availableToAssign}'),
                onTap: () => Navigator.pop(ctx, o),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;

    final qty = selected.availableToAssign.clamp(1, card.fillStatus.unfilledQty);
    try {
      await api.assignToDeck(
        deckId: widget.deckId,
        deckCardId: card.id,
        collectionEntryId: selected.collectionEntryId,
        quantity: qty,
      );
      await _refreshStores();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  List<DeckCardItem> _cardsForBoard(DeckDetails deck, String board) {
    return deck.cards.where((c) => c.board == board).toList();
  }

  @override
  Widget build(BuildContext context) {
    final detailStore = context.watch<DeckDetailStore>();
    final deck = detailStore.deckFor(widget.deckId);
    final loading = detailStore.isLoading(widget.deckId);
    final error = detailStore.errorFor(widget.deckId);

    if (loading && deck == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    if (error != null && deck == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ApiErrorView(
          message: error,
          onRetry: () => detailStore.load(widget.deckId),
        ),
      );
    }
    if (deck == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check),
            onPressed: () => _validateAndSave(deck),
            tooltip: 'Waliduj',
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteDeck),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => detailStore.refresh(widget.deckId),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('${deck.format} • ${deck.cards.length} pozycji'),
            if (deck.description != null) Text(deck.description!),
            const SizedBox(height: 8),
            for (final board in deckBoards) ...[
              if (_cardsForBoard(deck, board).isNotEmpty) ...[
                Text(
                  board.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ..._cardsForBoard(deck, board).map(
                  (card) => ListTile(
                    leading: card.imageUrl != null
                        ? Image.network(card.imageUrl!, width: 40, fit: BoxFit.cover)
                        : const Icon(Icons.style),
                    title: Text('${card.quantity}x ${card.name ?? card.scryfallId}'),
                    subtitle: card.formatWarning != null
                        ? Text(
                            card.formatWarning!.message,
                            style: const TextStyle(color: Colors.orange),
                          )
                        : Text(card.setCode ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FillStatusIndicator(fillStatus: card.fillStatus),
                        if (card.fillStatus.unfilledQty > 0)
                          IconButton(
                            icon: const Icon(Icons.link),
                            onPressed: () => _assignCopies(card),
                            tooltip: 'Przypisz',
                          ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeCard(card),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardSearchScreen()),
        ).then((_) => _refreshStores()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
