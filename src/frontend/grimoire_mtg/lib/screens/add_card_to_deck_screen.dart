import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';
import '../utils/card_grid.dart';
import '../utils/collection_grouping.dart';
import '../widgets/add_card_to_deck_sheet.dart';
import '../widgets/api_error_view.dart';
import '../widgets/card_search_body.dart';
import '../widgets/collection_filters_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/mtg_card_tile.dart';

class AddCardToDeckScreen extends StatefulWidget {
  const AddCardToDeckScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<AddCardToDeckScreen> createState() => _AddCardToDeckScreenState();
}

class _AddCardToDeckScreenState extends State<AddCardToDeckScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _nameFilterController = TextEditingController();

  CollectionFilters _apiFilters = CollectionFilters();
  List<CollectionEntryDto> _entries = [];
  bool _loadingCollection = false;
  String? _collectionError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameFilterController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCollection());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadCollection() async {
    setState(() {
      _loadingCollection = true;
      _collectionError = null;
    });
    try {
      final response = await context.read<AuthService>().api.getCollection(_apiFilters);
      if (mounted) {
        setState(() {
          _entries = response.entries;
          _loadingCollection = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _collectionError = e.message;
          _loadingCollection = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _collectionError = context.l10n.errorLoadCollection;
          _loadingCollection = false;
        });
      }
    }
  }

  Future<void> _showFilters() async {
    final result = await showCollectionFiltersDialog(
      context,
      initial: _apiFilters,
    );
    if (result == null) return;
    setState(() => _apiFilters = result);
    await _loadCollection();
  }

  Future<void> _onCardSelected(
    CardDto card, {
    List<CollectionEntryDto>? collectionEntries,
  }) async {
    final added = await showAddCardToDeckSheet(
      context,
      deckId: widget.deckId,
      card: card,
      collectionEntries: collectionEntries,
    );
    if (added == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildCollectionTab() {
    final l10n = context.l10n;
    if (_loadingCollection && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_collectionError != null && _entries.isEmpty) {
      return ApiErrorView(message: _collectionError!, onRetry: _loadCollection);
    }

    if (_entries.isEmpty && !_apiFilters.hasActiveFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.addCardToDeckEmptyCollection,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final nameFilter = _nameFilterController.text.trim().toLowerCase();
    var grouped = groupCollectionEntries(_entries);
    if (nameFilter.isNotEmpty) {
      grouped = grouped
          .where((g) => (g.card.name ?? '').toLowerCase().contains(nameFilter))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameFilterController,
                  decoration: InputDecoration(
                    hintText: l10n.addCardToDeckSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _showFilters,
                tooltip: l10n.addCardToDeckFilters,
                icon: Badge(
                  isLabelVisible: _apiFilters.hasActiveFilters,
                  child: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
        ),
        if (_apiFilters.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_apiFilters.summary(l10n), overflow: TextOverflow.ellipsis),
                onDeleted: () {
                  setState(() => _apiFilters = CollectionFilters());
                  _loadCollection();
                },
              ),
            ),
          ),
        if (_loadingCollection) const LinearProgressIndicator(),
        Expanded(
          child: grouped.isEmpty
              ? Center(
                  child: Text(
                    _apiFilters.hasActiveFilters || nameFilter.isNotEmpty
                        ? l10n.addCardToDeckNoFilterMatch
                        : l10n.collectionEmpty,
                  ),
                )
              : ContentWidth(
                  maxWidth: 1400,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: cardGridDelegate(context),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return MtgCardTile(
                        card: group.card,
                        subtitle: group.subtitleSummary,
                        onTap: () => _onCardSelected(
                          group.card,
                          collectionEntries: group.entries,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addCardToDeckTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.addCardToDeckTabCollection, icon: const Icon(Icons.grid_view)),
            Tab(text: l10n.addCardToDeckTabSearch, icon: const Icon(Icons.search)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollectionTab(),
          CardSearchBody(
            onCardTap: (card) => _onCardSelected(card),
            emptyHint: l10n.cardSearchMinChars,
          ),
        ],
      ),
    );
  }
}
