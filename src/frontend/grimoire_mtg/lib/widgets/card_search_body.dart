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
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await context.read<AuthService>().api.searchCards(query);
      if (mounted) {
        setState(() {
          _results = cards;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
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
        Expanded(
          child: _error != null
              ? ApiErrorView(message: _error!, onRetry: () => _search(_controller.text))
              : _results.isEmpty
                  ? Center(child: Text(widget.emptyHint))
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
