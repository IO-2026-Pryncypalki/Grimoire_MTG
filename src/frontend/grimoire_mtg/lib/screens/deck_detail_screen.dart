import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
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
import 'import_deck_list_screen.dart';

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
  bool _exporting = false;

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
    final l10n = context.l10n;
    final result = validateDeck(deck, l10n);
    try {
      await context.read<AuthService>().api.updateDeck(
            widget.deckId,
            isValid: result.isFormatValid,
            lastValidatedAt: DateTime.now().toUtc().toIso8601String(),
          );
      if (mounted) {
        final body = StringBuffer();
        if (result.formatMessages.isEmpty) {
          body.writeln(l10n.deckFormatNoIssues);
        } else {
          body.writeln(l10n.deckFormatIssues);
          for (final m in result.formatMessages) {
            body.writeln('• $m');
          }
        }
        body.writeln();
        if (result.isFullyAssigned) {
          body.writeln(l10n.deckAssignmentsAll);
        } else if (result.assignmentMessages.isEmpty) {
          body.writeln(l10n.deckAssignmentsEmpty);
        } else {
          body.writeln(l10n.deckAssignmentsIssues);
          for (final m in result.assignmentMessages) {
            body.writeln('• $m');
          }
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deckValidationTitle),
            content: Text(body.toString().trim()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonOK)),
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
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.deckDeleteConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
          ],
        );
      },
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
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.deckRemoveConfirm),
          content: Text(
            card.quantity > 1
                ? l10n.deckRemoveAllCopies(card.quantity, name)
                : l10n.deckRemoveCard(name),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
          ],
        );
      },
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
    final assignable = options.where((o) => o.assignableToSlot > 0).toList();
    if (assignable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.deckNoAvailableCopies),
        ),
      );
      return;
    }

    final selected = await _showCollectionOptionPicker(assignable);

    if (selected == null) return;

    String? preferredSourceDeckId;
    if (selected.assignedElsewhere > 0) {
      preferredSourceDeckId = await _pickTransferSource(selected);
      if (!mounted || preferredSourceDeckId == null) return;
    }

    final maxQty = selected.assignableToSlot.clamp(1, card.fillStatus.unfilledQty);
    final qty = maxQty;
    try {
      await api.assignToDeck(
        deckId: widget.deckId,
        deckCardId: card.id,
        collectionEntryId: selected.collectionEntryId,
        quantity: qty,
        preferredSourceDeckId: preferredSourceDeckId,
      );
      await _refreshStores();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<String?> _pickTransferSource(CollectionOptionDto option) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        String? selected =
            option.transferSources.length == 1 ? option.transferSources.first.deckId : null;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(l10n.deckTransferCopies),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.deckTransferPickSource),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (v) => setState(() => selected = v),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: option.transferSources
                          .map(
                            (s) => RadioListTile<String>(
                              value: s.deckId,
                              title: Text(l10n.deckTransferSource(s.quantity, s.deckName)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: selected == null ? null : () => Navigator.pop(ctx, selected),
                  child: Text(l10n.commonTransfer),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _collectionOptionSubtitle(CollectionOptionDto o, AppLocalizations l10n) {
    final version = o.isExactPrinting
        ? (o.setCode ?? '')
        : l10n.deckOptionOtherVersion(o.setCode ?? '?');
    if (o.availableToAssign > 0) {
      return l10n.deckOptionFree(o.availableToAssign, o.assignableToSlot, version);
    }
    if (o.assignedElsewhere > 0) {
      return l10n.deckOptionTransfer(o.assignableToSlot, o.assignedElsewhere, version);
    }
    return l10n.deckOptionSlot(o.assignableToSlot, version);
  }

  Future<CollectionOptionDto?> _showCollectionOptionPicker(
    List<CollectionOptionDto> options,
  ) {
    Widget buildPicker(void Function(CollectionOptionDto option) onSelect) {
      final l10n = context.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.deckAssignFromCollection)),
            ...options.map(
              (o) => ListTile(
                title: Text('${o.condition}${o.isFoil ? ' Foil' : ''}'),
                subtitle: Text(_collectionOptionSubtitle(o, l10n)),
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

  Future<void> _exportDeckToClipboard() async {
    if (_exporting) return;

    setState(() => _exporting = true);
    try {
      final text = await context.read<AuthService>().api.exportDeckList(widget.deckId);
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              text.isEmpty
                  ? l10n.deckExportEmpty
                  : l10n.deckExportCopied,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _assignDeckFromCollectionByName(DeckDetails deck) async {
    final unfilled = deck.cards.fold<int>(
      0,
      (sum, c) => sum + c.fillStatus.unfilledQty,
    );
    if (unfilled <= 0) return;

    final confirm = unfilled > 10
        ? await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l10n = AppLocalizations.of(ctx)!;
              return AlertDialog(
                title: Text(l10n.deckFillFromCollection),
                content: Text(
                  l10n.deckFillFromCollectionBody(unfilled),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonFill)),
                ],
              );
            },
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
        final l10n = context.l10n;
        final skipped = summary.skippedNoCollection > 0
            ? l10n.deckAssignedSkipped(summary.skippedNoCollection)
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.deckAssignedSummary(summary.assignedCopies, summary.assignedSlots, skipped),
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
    final l10n = context.l10n;
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
              tooltip: l10n.deckFillFromCollectionTooltip,
            ),
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _exporting ? null : _exportDeckToClipboard,
            tooltip: l10n.deckExportList,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImportDeckListScreen(deckId: widget.deckId),
              ),
            ).then((_) => _refreshStores()),
            tooltip: l10n.deckImportList,
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
              tooltip: l10n.deckAddCard,
            ),
          IconButton(
            icon: const Icon(Icons.fact_check),
            onPressed: () => _validateAndSave(deck),
            tooltip: l10n.deckValidate,
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
