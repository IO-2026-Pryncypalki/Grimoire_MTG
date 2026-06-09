import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../state/deck_store.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/add_to_collection_sheet.dart';
import '../widgets/api_error_view.dart';
import '../widgets/collection_entry_panel.dart';
import '../widgets/content_width.dart';
import '../widgets/mana_symbol_text.dart';
import '../utils/scryfall_image_url.dart';
import '../widgets/mtg_network_card_image.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.scryfallId,
    this.initialCard,
    this.collectionEntry,
  });

  final String scryfallId;
  final CardDetailDto? initialCard;
  final CollectionEntryDto? collectionEntry;

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
    if (widget.initialCard != null) {
      _card = widget.initialCard;
      _loading = false;
      _refreshInBackground();
    } else {
      _load();
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final card = await context.read<AuthService>().api.getCardDetails(widget.scryfallId);
      if (mounted) {
        setState(() => _card = card);
      }
    } on ApiException {
      // Scan already returned card data; keep showing initialCard.
    }
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
    final added = await showAddToCollection(
      context,
      scryfallId: widget.scryfallId,
      initialName: _card?.name,
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cardAddToCollection)),
      );
    }
  }

  Future<void> _showAddToDeck() async {
    final api = context.read<AuthService>().api;
    final decks = await api.listDecks();
    if (!mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cardCreateDeckFirst)),
      );
      return;
    }

    final deckId = await _showDeckPicker(decks);
    if (deckId == null) return;

    try {
      await api.addCardToDeck(deckId: deckId, scryfallId: widget.scryfallId);
      await syncAfterLocalMutation(context, collection: true, decks: true, refreshAll: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cardAddToDeck)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<String?> _showDeckPicker(List<DeckListItem> decks) {
    Widget buildPicker(void Function(String id) onSelect) {
      final l10n = context.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.cardSelectDeck)),
            ...decks.map(
              (d) => ListTile(
                title: Text(d.name),
                subtitle: Text(d.format),
                onTap: () => onSelect(d.id),
              ),
            ),
          ],
        ),
      );
    }

    if (context.isMediumUp) {
      return showDialog<String>(
        context: context,
        builder: (ctx) => Dialog(
          child: ContentWidth(
            maxWidth: 420,
            child: buildPicker((id) => Navigator.pop(ctx, id)),
          ),
        ),
      );
    }

    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => buildPicker((id) => Navigator.pop(ctx, id)),
    );
  }

  Future<void> _openScryfall(String uri) async {
    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String? _formatSetLine(CardDetailDto card) {
    final parts = <String>[];
    if (card.setName != null && card.setName!.isNotEmpty) {
      parts.add(card.setName!);
    } else if (card.setCode != null) {
      parts.add(card.setCode!.toUpperCase());
    }
    if (card.collectorNumber != null) {
      parts.add('#${card.collectorNumber}');
    }
    if (card.lang != null && card.lang!.isNotEmpty) {
      parts.add(card.lang!.toUpperCase());
    }
    return parts.isEmpty ? null : parts.join(' • ');
  }

  Widget _buildColorChips(List<String> colors, String label) {
    if (colors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$label:', style: Theme.of(context).textTheme.bodySmall),
          ...colors.map(
            (c) => Chip(
              label: Text(c),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLine(String label, double? value) {
    if (value == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Text(
      '$label: ${NumberFormat.simpleCurrency(locale: locale).format(value)}',
      style: const TextStyle(color: Colors.greenAccent),
    );
  }

  Widget _buildDetails(CardDetailDto card) {
    final l10n = context.l10n;
    final setLine = _formatSetLine(card);
    final pt = card.power != null && card.toughness != null
        ? '${card.power}/${card.toughness}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (setLine != null) ...[
          Text(setLine, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        Text(card.typeLine ?? '', style: Theme.of(context).textTheme.titleMedium),
        if (card.manaCost != null) ...[
          const SizedBox(height: 4),
          ManaSymbolText(card.manaCost!, symbolSize: 18),
        ],
        if (card.cmc != null)
          Text('CMC: ${card.cmc!.toStringAsFixed(card.cmc! % 1 == 0 ? 0 : 1)}'),
        if (pt != null) Text(l10n.cardPowerToughness(pt)),
        if (card.rarity != null) Text(l10n.cardRarity(card.rarity!)),
        _buildColorChips(card.colors, l10n.cardColors),
        _buildColorChips(card.colorIdentity, l10n.cardColorIdentity),
        const SizedBox(height: 8),
        _buildPriceLine('USD', card.priceUsd ?? card.price),
        _buildPriceLine('USD Foil', card.priceUsdFoil),
        _buildPriceLine('EUR', card.priceEur),
        _buildPriceLine('EUR Foil', card.priceEurFoil),
        if (card.oracleText != null) ...[
          const SizedBox(height: 12),
          ManaSymbolText(card.oracleText!),
        ],
        if (card.scryfallUri != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _openScryfall(card.scryfallUri!),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.cardOpenScryfall),
          ),
        ],
        if (widget.collectionEntry != null) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          CollectionEntryPanel(
            entry: widget.collectionEntry!,
            onEntryRemoved: () {
              if (mounted) Navigator.pop(context, true);
            },
          ),
        ],
        if (widget.collectionEntry == null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _showAddToCollection,
                  child: Text(l10n.cardCollectionButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showAddToDeck,
                  child: Text(l10n.cardDeckButton),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _hasDisplayableImage(CardDetailDto card) {
    return cardImageUrlForDisplay(
          imageUrl: card.imageUrl,
          imageUrlHiRes: card.imageUrlHiRes,
          tier: CardImageTier.detail,
        ) !=
        null;
  }

  Widget _buildCardImage(CardDetailDto card) {
    if (!_hasDisplayableImage(card)) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: kMtgCardAspectRatio,
        child: ColoredBox(
          color: Colors.black12,
          child: MtgNetworkCardImage(
            imageUrl: card.imageUrl,
            imageUrlHiRes: card.imageUrlHiRes,
            tier: CardImageTier.detail,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
    final wide = context.isMediumUp;
    final showImage = _hasDisplayableImage(card);

    return Scaffold(
      appBar: AppBar(title: Text(card.name ?? l10n.cardDefaultName)),
      body: ContentWidth(
        maxWidth: 900,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showImage)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: _buildCardImage(card),
                      ),
                    if (showImage) const SizedBox(width: 24),
                    Expanded(child: _buildDetails(card)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardImage(card),
                    const SizedBox(height: 16),
                    _buildDetails(card),
                  ],
                ),
        ),
      ),
    );
  }
}
