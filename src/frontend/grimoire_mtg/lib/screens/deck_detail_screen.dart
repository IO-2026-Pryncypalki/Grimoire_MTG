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
            isValid: result.isFormatValid,
            lastValidatedAt: DateTime.now().toUtc().toIso8601String(),
          );
      if (mounted) {
        final body = StringBuffer();
        if (result.formatMessages.isEmpty) {
          body.writeln('Format: bez uwag.');
        } else {
          body.writeln('Format:');
          for (final m in result.formatMessages) {
            body.writeln('• $m');
          }
        }
        body.writeln();
        if (result.isFullyAssigned) {
          body.writeln('Przypisania: wszystkie kopie z kolekcji.');
        } else if (result.assignmentMessages.isEmpty) {
          body.writeln('Przypisania: brak kart w talii.');
        } else {
          body.writeln('Przypisania:');
          for (final m in result.assignmentMessages) {
            body.writeln('• $m');
          }
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Walidacja talii'),
            content: Text(body.toString().trim()),
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
        const SnackBar(content: Text('Brak kopii o tej nazwie w kolekcji')),
      );
      return;
    }

    final selected = await _showCollectionOptionPicker(options);

    if (selected == null) return;

    if (selected.assignedElsewhere > 0) {
      final confirmed = await _confirmTransferAssignment(selected);
      if (confirmed != true) return;
    }

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

  Future<bool?> _confirmTransferAssignment(CollectionOptionDto option) {
    final sources = option.transferSources
        .map((s) => '${s.quantity}× z talii „${s.deckName}”')
        .join('\n');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przenieść kopie?'),
        content: Text(
          'Ten wpis ma ${option.assignedElsewhere} kopii przypisanych w innej talii.\n\n'
          'Przypisywanie tutaj usunie je stamtąd:\n$sources',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Przenieś')),
        ],
      ),
    );
  }

  String _collectionOptionSubtitle(CollectionOptionDto o) {
    final version = o.isExactPrinting
        ? (o.setCode ?? '')
        : '${o.setCode ?? '?'} • inna wersja';
    final base = 'Dostępne: ${o.availableToAssign} • $version';
    if (o.assignedElsewhere > 0) {
      return '$base\n${o.assignedElsewhere} w innej talii — przypisanie przeniesie kopie';
    }
    return base;
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
                subtitle: Text(_collectionOptionSubtitle(o)),
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

  bool _deckHasUnfilledSlots(DeckDetails deck) =>
      deck.cards.any((c) => c.fillStatus.unfilledQty > 0);

  Future<void> _assignDeckFromCollectionByName(DeckDetails deck) async {
    final unfilled = deck.cards.fold<int>(
      0,
      (sum, c) => sum + c.fillStatus.unfilledQty,
    );
    if (unfilled <= 0) return;

    final confirm = unfilled > 10
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Uzupełnij z kolekcji?'),
              content: Text(
                'Przypisać kopie z kolekcji do $unfilled brakujących slotów (dopasowanie po nazwie karty)?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Uzupełnij')),
              ],
            ),
          )
        : true;

    if (confirm != true) return;

    try {
      final summary = await context
          .read<AuthService>()
          .api
          .assignDeckFromCollectionByName(widget.deckId);
      await _refreshStores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Przypisano ${summary.assignedCopies} kopii do ${summary.assignedSlots} pozycji'
              '${summary.skippedNoCollection > 0 ? ' • ${summary.skippedNoCollection} bez kopii' : ''}',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
          if (_deckHasUnfilledSlots(deck))
            IconButton(
              icon: const Icon(Icons.playlist_add_check),
              onPressed: () => _assignDeckFromCollectionByName(deck),
              tooltip: 'Uzupełnij z kolekcji',
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
