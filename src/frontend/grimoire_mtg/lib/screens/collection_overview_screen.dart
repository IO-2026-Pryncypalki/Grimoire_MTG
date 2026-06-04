import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../utils/card_grid.dart';
import '../utils/responsive.dart';
import '../widgets/api_error_view.dart';
import '../widgets/collection_filters_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/mtg_card_tile.dart';
import 'card_detail_screen.dart';
import 'card_search_screen.dart';

class CollectionOverviewScreen extends StatefulWidget {
  const CollectionOverviewScreen({super.key});

  @override
  State<CollectionOverviewScreen> createState() => _CollectionOverviewScreenState();
}

class _CollectionOverviewScreenState extends State<CollectionOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<CollectionStore>();
      if (store.data == null && !store.loading) {
        store.load();
      }
    });
  }

  Future<void> _showFilters(CollectionStore store) async {
    final result = await showCollectionFiltersDialog(
      context,
      initial: store.filters,
    );
    if (result == null) return;
    await store.reloadWithFilters(result);
  }

  Future<void> _refreshPrices(CollectionStore store) async {
    try {
      final result = await context.read<AuthService>().api.refreshPrices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zaktualizowano ${result['updatedCards']}/${result['totalCards']} kart',
            ),
          ),
        );
        await store.refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CollectionStore>();
    final data = store.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moja Kolekcja'),
        actions: [
          if (store.refreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(store),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshPrices(store),
            tooltip: 'Odśwież ceny',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CardSearchScreen()),
            ),
          ),
        ],
      ),
      body: store.loading && data == null
          ? const Center(child: CircularProgressIndicator())
          : store.error != null && data == null
              ? ApiErrorView(message: store.error!, onRetry: store.load)
              : ContentWidth(
                  maxWidth: 1400,
                  child: RefreshIndicator(
                    onRefresh: store.refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Wartość: ${NumberFormat.simpleCurrency().format(data?.totalValue ?? 0)} • ${data?.entries.length ?? 0} wpisów',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        if (data == null || data.entries.isEmpty)
                          const SliverFillRemaining(
                            child: Center(child: Text('Kolekcja jest pusta')),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.all(8),
                            sliver: SliverGrid(
                              gridDelegate: cardGridDelegate(context),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final entry = data.entries[index];
                                  return MtgCardTile(
                                    card: entry.toCardDto(),
                                    subtitle: 'x${entry.quantity} ${entry.condition}${entry.isFoil ? ' ✨' : ''}',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CardDetailScreen(
                                          scryfallId: entry.scryfallId,
                                          collectionEntry: entry,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: data.entries.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: context.isMediumUp
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CardSearchScreen()),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }
}
