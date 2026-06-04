import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/scan.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../state/deck_store.dart';
import '../utils/sync_after_mutation.dart';
import '../utils/card_grid.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/mtg_card_tile.dart';
import 'card_detail_screen.dart';
import 'card_search_screen.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key, required this.scanResult});

  final ScanResponse scanResult;

  Future<void> _addToCollection(BuildContext context, CardDto card) async {
    final added = await showAddToCollection(
      context,
      scryfallId: card.scryfallId,
      initialName: card.name,
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dodano do kolekcji')),
      );
    }
  }

  Future<void> _addToDeck(BuildContext context, CardDto card) async {
    final api = context.read<AuthService>().api;
    final decks = await api.listDecks();
    if (!context.mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utwórz talię w zakładce Talie')),
      );
      return;
    }

    final deckId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: decks
              .map(
                (d) => ListTile(
                  title: Text(d.name),
                  onTap: () => Navigator.pop(ctx, d.id),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (deckId == null) return;

    try {
      await api.addToCollection(scryfallId: card.scryfallId);
      await api.addCardToDeck(deckId: deckId, scryfallId: card.scryfallId);
      await syncAfterLocalMutation(
        context,
        collection: true,
        decks: true,
        refreshAll: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dodano do kolekcji i talii')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (scanResult.isNone) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skan')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nie rozpoznano karty'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CardSearchScreen()),
                ),
                child: const Text('Wyszukaj ręcznie'),
              ),
            ],
          ),
        ),
      );
    }

    final cards = scanResult.cards;
    final primary = cards.isNotEmpty ? cards.first : null;

    if (scanResult.isUnique && primary != null) {
      return CardDetailScreen(
        scryfallId: primary.scryfallId,
        initialCard: primary,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wybierz wariant')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: cardGridDelegate(context),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return MtgCardTile(
            card: card,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CardDetailScreen(
                  scryfallId: card.scryfallId,
                  initialCard: card,
                ),
              ),
            ),
            trailing: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.collections, size: 18),
                  onPressed: () => _addToCollection(context, card),
                ),
                IconButton(
                  icon: const Icon(Icons.layers, size: 18),
                  onPressed: () => _addToDeck(context, card),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
