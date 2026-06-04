import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/deck.dart';
import '../models/deck_view_mode.dart';
import '../services/auth_service.dart';
import '../services/deck_view_mode_prefs.dart';
import '../services/sync_service.dart';
import '../state/deck_detail_store.dart';
import '../state/deck_store.dart';
import '../utils/deck_validator.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/api_error_view.dart';
import '../widgets/content_width.dart';
import '../widgets/deck_card_actions.dart';
import '../widgets/deck_cards_grid_view.dart';
import '../widgets/deck_cards_list_view.dart';
import '../widgets/deck_cards_stack_view.dart';
import '../widgets/deck_view_mode_switcher.dart';
import 'add_card_to_deck_screen.dart';
import 'card_detail_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  late final SyncService _sync;
  DeckViewMode _viewMode = DeckViewMode.list;
  bool _viewModeLoaded = false;

  @override
  void initState() {
    super.initState();
    _sync = context.read<SyncService>();
    _sync.setActiveDeckId(widget.deckId);
    _loadViewMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<DeckDetailStore>();
      if (store.deckFor(widget.deckId) == null && !store.isLoading(widget.deckId)) {
        store.load(widget.deckId);
      }
    });
  }

  Future<void> _loadViewMode() async {
    final mode = await DeckViewModePrefs.load();
    if (mounted) {
      setState(() {
        _viewMode = mode;
        _viewModeLoaded = true;
      });
    }
  }

  Future<void> _setViewMode(DeckViewMode mode) async {
    setState(() => _viewMode = mode);
    await DeckViewModePrefs.save(mode);
  }

  @override
  void dispose() {
    _sync.setActiveDeckId(null);
    super.dispose();
  }

  Future<void> _refreshStores() async {
    await syncAfterLocalMutation(
      context,
      decks: true,
      deckId: widget.deckId,
      refreshAll: false,
    );
  }

  DeckCardActions _cardActions() {
    return DeckCardActions(
      onAssign: _assignCopies,
      onRemove: _removeCard,
      onOpenDetail: _openCardDetail,
    );
  }

  void _openCardDetail(DeckCardItem card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardDetailScreen(scryfallId: card.scryfallId),
      ),
    );
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
      await syncAfterLocalMutation(context, decks: true, refreshAll: false);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _removeCard(DeckCardItem card) async {
    final name = card.name ?? card.scryfallId;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć z talii?'),
        content: Text(
          card.quantity > 1
              ? 'Usunąć wszystkie ${card.quantity} kopie: $name?'
              : 'Usunąć kartę: $name?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<AuthService>().api.removeCardFromDeck(
            deckId: widget.deckId,
            scryfallId: card.scryfallId,
            board: card.board,
            quantity: card.quantity,
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

    final selected = await _showCollectionOptionPicker(options);

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

  Future<CollectionOptionDto?> _showCollectionOptionPicker(
    List<CollectionOptionDto> options,
  ) {
    Widget buildPicker(void Function(CollectionOptionDto option) onSelect) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Przypisz kopie z kolekcji')),
            ...options.map(
              (o) => ListTile(
                title: Text('${o.condition}${o.isFoil ? ' Foil' : ''}'),
                subtitle: Text('Dostępne: ${o.availableToAssign}'),
                onTap: () => onSelect(o),
              ),
            ),
          ],
        ),
      );
    }

    if (context.isMediumUp) {
      return showDialog<CollectionOptionDto>(
        context: context,
        builder: (ctx) => Dialog(
          child: ContentWidth(
            maxWidth: 420,
            child: buildPicker((o) => Navigator.pop(ctx, o)),
          ),
        ),
      );
    }

    return showModalBottomSheet<CollectionOptionDto>(
      context: context,
      builder: (ctx) => buildPicker((o) => Navigator.pop(ctx, o)),
    );
  }

  Widget _cardsView(DeckDetails deck) {
    final actions = _cardActions();
    return switch (_viewMode) {
      DeckViewMode.list => DeckCardsListView(deck: deck, actions: actions),
      DeckViewMode.grid => DeckCardsGridView(deck: deck, actions: actions),
      DeckViewMode.stack => DeckCardsStackView(deck: deck, actions: actions),
    };
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
          if (_viewModeLoaded)
            DeckViewModeSwitcher(
              mode: _viewMode,
              onChanged: _setViewMode,
              inAppBar: true,
            ),
          if (context.isMediumUp)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardToDeckScreen(deckId: widget.deckId),
                ),
              ).then((_) => _refreshStores()),
              tooltip: 'Dodaj kartę',
            ),
          IconButton(
            icon: const Icon(Icons.fact_check),
            onPressed: () => _validateAndSave(deck),
            tooltip: 'Waliduj',
          ),
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteDeck),
        ],
      ),
      body: ContentWidth(
        maxWidth: context.isExpanded ? 1400 : (context.isMediumUp ? 1200 : 960),
        child: RefreshIndicator(
          onRefresh: () => detailStore.refresh(widget.deckId),
          child: _cardsView(deck),
        ),
      ),
      floatingActionButton: context.isMediumUp
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardToDeckScreen(deckId: widget.deckId),
                ),
              ).then((_) => _refreshStores()),
              child: const Icon(Icons.add),
            ),
    );
  }
}
