import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/card.dart';
import '../models/scan.dart';
import '../services/auth_service.dart';
import '../utils/card_printing_line.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/add_to_collection_sheet.dart';
import 'card_detail_screen.dart';
import 'card_search_screen.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.scanResult});

  final ScanResponse scanResult;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final TextEditingController _filterController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() {
      setState(() {
        _query = _filterController.text;
      });
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  ScanResponse get scanResult => widget.scanResult;

  List<CardDetailDto> get _filteredCards {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return scanResult.cards;
    return scanResult.cards.where((c) {
      return (c.setCode?.toLowerCase().contains(q) ?? false) ||
          (c.collectorNumber?.toLowerCase().contains(q) ?? false) ||
          (c.releasedYear?.toString().contains(q) ?? false);
    }).toList();
  }

  Future<void> _addToCollection(BuildContext context, CardDto card) async {
    final added = await showAddToCollection(
      context,
      scryfallId: card.scryfallId,
      initialName: card.name,
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cardAddToCollection)),
      );
    }
  }

  Future<void> _addToDeck(BuildContext context, CardDto card) async {
    final api = context.read<AuthService>().api;
    final decks = await api.listDecks();
    if (!context.mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanCreateDeckInTab)),
      );
      return;
    }

    final deckId = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(l10n.cardSelectDeck)),
              ...decks.map(
                (d) => ListTile(
                  title: Text(d.name),
                  onTap: () => Navigator.pop(ctx, d.id),
                ),
              ),
            ],
          ),
        );
      },
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
          SnackBar(content: Text(context.l10n.scanAddedToCollectionAndDeck)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
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
    final l10n = context.l10n;
    if (scanResult.isNone) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.scanNotRecognized),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const CardSearchScreen()),
                ),
                child: Text(l10n.scanSearchManually),
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
      appBar: AppBar(title: Text(l10n.scanSelectVariant)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _filterController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: l10n.scanFilterHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _filterController.clear(),
                      ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCards.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _variantTile(context, _filteredCards[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantTile(BuildContext context, CardDetailDto card) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final printingLine = formatCardPrintingLine(card);
    final price = card.price;
    final priceText =
        price != null ? NumberFormat.simpleCurrency(locale: locale).format(price) : null;

    return ListTile(
      title: Text(card.name ?? l10n.cardDefaultName),
      subtitle: printingLine == null && priceText == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (printingLine != null) Text(printingLine),
                if (priceText != null)
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.greenAccent,
                        ),
                  ),
              ],
            ),
      isThreeLine: printingLine != null && priceText != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.collections),
            tooltip: l10n.cardAddToCollection,
            onPressed: () => _addToCollection(context, card),
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: l10n.addToDeckTitle,
            onPressed: () => _addToDeck(context, card),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CardDetailScreen(
            scryfallId: card.scryfallId,
            initialCard: card,
          ),
        ),
      ),
    );
  }
}
