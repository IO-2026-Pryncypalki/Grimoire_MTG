import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/deck_store.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/api_error_view.dart';
import '../widgets/content_width.dart';
import '../widgets/deck_overview_tile.dart';
import 'create_deck_screen.dart';
import 'deck_detail_screen.dart';

class DeckOverviewScreen extends StatefulWidget {
  const DeckOverviewScreen({super.key});

  @override
  State<DeckOverviewScreen> createState() => _DeckOverviewScreenState();
}

class _DeckOverviewScreenState extends State<DeckOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<DeckStore>();
      if (store.decks.isEmpty && !store.loading) {
        store.load();
      }
    });
  }

  Future<void> _openCreateDeck() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
    );
    if (created == true && mounted) {
      await syncAfterLocalMutation(context, decks: true, refreshAll: false);
    }
  }

  Future<void> _openDeck(String deckId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeckDetailScreen(deckId: deckId)),
    );
    if (!mounted) return;
    await context.read<DeckStore>().refresh(silent: true);
  }

  int _gridCrossAxisCount(double width) {
    if (width >= 1000) return 3;
    if (width >= 640) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje Talie'),
        actions: [
          if (context.isMediumUp)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openCreateDeck,
              tooltip: 'Nowa talia',
            ),
          if (store.refreshing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: store.loading && store.decks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : store.error != null && store.decks.isEmpty
              ? ApiErrorView(message: store.error!, onRetry: store.load)
              : ContentWidth(
                  maxWidth: 1200,
                  child: RefreshIndicator(
                    onRefresh: store.refresh,
                    child: store.decks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('Brak talii — utwórz pierwszą')),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  _gridCrossAxisCount(constraints.maxWidth);

                              if (crossAxisCount == 1) {
                                return ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: store.decks.length,
                                  itemBuilder: (context, index) {
                                    final deck = store.decks[index];
                                    return DeckOverviewTile(
                                      deck: deck,
                                      compact: true,
                                      onTap: () => _openDeck(deck.id),
                                    );
                                  },
                                );
                              }

                              return GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.35,
                                ),
                                itemCount: store.decks.length,
                                itemBuilder: (context, index) {
                                  final deck = store.decks[index];
                                  return DeckOverviewTile(
                                    deck: deck,
                                    onTap: () => _openDeck(deck.id),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
      floatingActionButton: context.isMediumUp
          ? null
          : FloatingActionButton(
              onPressed: _openCreateDeck,
              child: const Icon(Icons.add),
            ),
    );
  }
}
