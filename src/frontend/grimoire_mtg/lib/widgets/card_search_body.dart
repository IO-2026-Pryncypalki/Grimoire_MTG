import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/card.dart';
import '../services/auth_service.dart';
import '../utils/card_grid.dart';
import '../widgets/api_error_view.dart';
import '../widgets/content_width.dart';
import '../widgets/mtg_card_tile.dart';

class CardSearchBody extends StatefulWidget {
  const CardSearchBody({
    super.key,
    required this.onCardTap,
    this.emptyHint = 'Wpisz co najmniej 2 znaki',
  });

  final void Function(CardDto card) onCardTap;
  final String emptyHint;

  @override
  State<CardSearchBody> createState() => _CardSearchBodyState();
}

class _CardSearchBodyState extends State<CardSearchBody> {
  final _controller = TextEditingController();
  Timer? _debounce;
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

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _error = null;
        _hasSearched = false;
        _noMatch = false;
        _didYouMean = const [];
        _lastQuery = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final result = await context.read<AuthService>().api.searchCards(query);
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
    if (!_hasSearched || (_lastQuery?.length ?? 0) < 2) {
      return Center(child: Text(widget.emptyHint));
    }

    if (_noMatch && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Nie znaleziono kart dla „$_lastQuery”',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_didYouMean.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Czy chodziło Ci o:',
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

    return Center(child: Text(widget.emptyHint));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Nazwa karty...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
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
                'Pokazano wyniki dla podobnych nazw',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: _error != null
              ? ApiErrorView(message: _error!, onRetry: () => _search(_controller.text))
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
