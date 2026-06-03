import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/card.dart';
import '../services/auth_service.dart';
import '../state/deck_store.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/api_error_view.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.scryfallId,
    this.initialCard,
  });

  final String scryfallId;
  final CardDto? initialCard;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  CardDetailDto? _card;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final card = await context.read<AuthService>().api.getCardDetails(widget.scryfallId);
      if (mounted) {
        setState(() {
          _card = card;
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

  Future<void> _showAddToCollection() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddToCollectionSheet(
        scryfallId: widget.scryfallId,
        initialName: _card?.name,
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodano do kolekcji')),
      );
    }
  }

  Future<void> _showAddToDeck() async {
    final api = context.read<AuthService>().api;
    final decks = await api.listDecks();
    if (!mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Najpierw utwórz talię')),
      );
      return;
    }

    final deckId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Wybierz talię')),
            ...decks.map(
              (d) => ListTile(
                title: Text(d.name),
                subtitle: Text(d.format),
                onTap: () => Navigator.pop(ctx, d.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (deckId == null) return;

    try {
      await api.addCardToDeck(deckId: deckId, scryfallId: widget.scryfallId);
      await context.read<DeckStore>().refresh(silent: true);
      await context.read<AuthService>().reloadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano do talii')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ApiErrorView(message: _error!, onRetry: _load),
      );
    }

    final card = _card!;
    final price = card.priceUsd ?? card.price;

    return Scaffold(
      appBar: AppBar(title: Text(card.name ?? 'Karta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (card.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: card.imageUrl!),
              ),
            const SizedBox(height: 16),
            Text(card.typeLine ?? '', style: Theme.of(context).textTheme.titleMedium),
            if (card.manaCost != null) Text(card.manaCost!),
            if (price != null)
              Text(
                NumberFormat.simpleCurrency().format(price),
                style: const TextStyle(color: Colors.greenAccent),
              ),
            const SizedBox(height: 12),
            if (card.oracleText != null) Text(card.oracleText!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _showAddToCollection,
                    child: const Text('Kolekcja'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _showAddToDeck,
                    child: const Text('Talia'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
