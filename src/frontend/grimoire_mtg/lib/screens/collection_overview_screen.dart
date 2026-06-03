import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/collection.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../widgets/api_error_view.dart';
import '../widgets/mtg_card_tile.dart';
import 'card_search_screen.dart';
import 'collection_entry_screen.dart';

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
    final colorCtrl = TextEditingController(text: store.filters.color);
    final typeCtrl = TextEditingController(text: store.filters.type);
    final editionCtrl = TextEditingController(text: store.filters.edition);
    final cmcCtrl = TextEditingController(
      text: store.filters.cmc?.toString() ?? '',
    );

    final applied = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Kolor (R, U, ...)'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Typ (Creature, ...)'),
              ),
              TextField(
                controller: editionCtrl,
                decoration: const InputDecoration(labelText: 'Edycja'),
              ),
              TextField(
                controller: cmcCtrl,
                decoration: const InputDecoration(labelText: 'CMC'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              store.setFilters(CollectionFilters());
              Navigator.pop(ctx, true);
            },
            child: const Text('Wyczyść'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(
            onPressed: () {
              store.setFilters(CollectionFilters(
                color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
                type: typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
                edition: editionCtrl.text.trim().isEmpty ? null : editionCtrl.text.trim(),
                cmc: int.tryParse(cmcCtrl.text.trim()),
              ));
              Navigator.pop(ctx, true);
            },
            child: const Text('Zastosuj'),
          ),
        ],
      ),
    );

    if (applied == true) await store.reloadWithFilters(store.filters);
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
              : RefreshIndicator(
                  onRefresh: store.refresh,
                  child: CustomScrollView(
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
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = data.entries[index];
                                return MtgCardTile(
                                  card: entry.toCardDto(),
                                  subtitle: 'x${entry.quantity} ${entry.condition}${entry.isFoil ? ' ✨' : ''}',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CollectionEntryScreen(entry: entry),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CardSearchScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
