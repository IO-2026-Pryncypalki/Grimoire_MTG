import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../models/card.dart';
import '../models/card_search_filters.dart';
import '../services/auth_service.dart';
import '../utils/card_grid.dart';
import '../utils/card_search_query.dart';
import '../utils/responsive.dart';
import '../widgets/api_error_view.dart';
import '../widgets/content_width.dart';
import '../widgets/mtg_card_tile.dart';
import '../widgets/search_filters_panel.dart';

class CardSearchBody extends StatefulWidget {
  const CardSearchBody({
    super.key,
    required this.onCardTap,
    this.emptyHint,
  });

  final void Function(CardDto card) onCardTap;
  final String? emptyHint;

  @override
  State<CardSearchBody> createState() => _CardSearchBodyState();
}

class _CardSearchBodyState extends State<CardSearchBody> {
  final _controller = TextEditingController();
  Timer? _debounce;
  CardSearchFilters _filters = const CardSearchFilters();
  List<CardDto> _results = [];
  bool _loading = false;
  String? _error;
  String? _lastQuery;
  bool _hasSearched = false;
  bool _noMatch = false;
  List<String> _didYouMean = const [];
  String _searchMode = 'direct';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool _hasEnoughInput(String trimmed) =>
      trimmed.length >= 2 || !_filters.isEmpty;

  void _clearResults() {
    setState(() {
      _results = [];
      _error = null;
      _hasSearched = false;
      _noMatch = false;
      _didYouMean = const [];
      _lastQuery = null;
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (!_hasEnoughInput(trimmed)) {
      _clearResults();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _search(trimmed),
    );
  }

  void _onFiltersChanged(CardSearchFilters filters) {
    _debounce?.cancel();
    setState(() => _filters = filters);
    final trimmed = _controller.text.trim();
    if (trimmed.length < 2 && filters.isEmpty) {
      _clearResults();
      return;
    }
    _search(trimmed);
  }

  Future<void> _search(String query) async {
    final fullQuery = buildCardSearchQuery(query, _filters);
    if (fullQuery.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final result = await context.read<AuthService>().api.searchCards(fullQuery);
      if (mounted) {
        setState(() {
          _results = result.cards;
          _noMatch = result.noMatch;
          _didYouMean = result.didYouMean;
          _searchMode = result.searchMode;
          _hasSearched = true;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _hasSearched = true;
          _loading = false;
        });
      }
    }
  }

  void _searchSuggestion(String name) {
    _controller.text = name;
    _controller.selection = TextSelection.collapsed(offset: name.length);
    _search(name);
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    final hint = widget.emptyHint ?? l10n.cardSearchMinCharsShort;

    if (!_hasSearched) {
      return Center(child: Text(hint));
    }

    if (_noMatch && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _lastQuery?.isNotEmpty == true
                    ? l10n.cardSearchNotFound(_lastQuery!)
                    : l10n.cardSearchNoResults,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_didYouMean.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.cardSearchDidYouMean,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: _didYouMean
                      .map(
                        (name) => ActionChip(
                          label: Text(name),
                          onPressed: () => _searchSuggestion(name),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(child: Text(hint));
  }

  Widget _buildFiltersPanel(BuildContext context) {
    final panel = SearchFiltersPanel(
      filters: _filters,
      onChanged: _onFiltersChanged,
    );
    if (context.isMediumUp) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: panel,
      );
    }
    final l10n = context.l10n;
    final count = _filters.activeCount;
    return ExpansionTile(
      leading: const Icon(Icons.tune),
      title: Text(
        count > 0 ? l10n.searchFiltersActive(count) : l10n.searchFiltersLabel,
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      children: [panel],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: l10n.cardSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        _buildFiltersPanel(context),
        if (_loading) const LinearProgressIndicator(),
        if (_hasSearched &&
            !_loading &&
            _error == null &&
            _results.isNotEmpty &&
            _searchMode == 'autocomplete')
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                l10n.cardSearchAutocomplete,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: _error != null
              ? ApiErrorView(
                  message: _error!,
                  onRetry: () => _search(_controller.text),
                )
              : _results.isEmpty
                  ? _buildEmptyState()
                  : ContentWidth(
                      maxWidth: 1400,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: cardGridDelegate(context),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final card = _results[index];
                          return MtgCardTile(
                            card: card,
                            onTap: () => widget.onCardTap(card),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
