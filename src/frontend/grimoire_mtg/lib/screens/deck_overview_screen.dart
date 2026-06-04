import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/deck_store.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/api_error_view.dart';
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
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
                );
                if (created == true && mounted) {
                  await syncAfterLocalMutation(context, decks: true, refreshAll: false);
                }
              },
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
              : RefreshIndicator(
                  onRefresh: store.refresh,
                  child: store.decks.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Brak talii — utwórz pierwszą')),
                          ],
                        )
                      : ListView.builder(
                          itemCount: store.decks.length,
                          itemBuilder: (context, index) {
                            final deck = store.decks[index];
                            return ListTile(
                              leading: const Icon(Icons.style),
                              title: Text(deck.name),
                              subtitle: Text(
                                '${deck.format}${deck.isValid == true ? ' • ✓' : deck.isValid == false ? ' • ✗' : ''}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeckDetailScreen(deckId: deck.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: context.isMediumUp
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
                );
                if (created == true && mounted) {
                  await syncAfterLocalMutation(context, decks: true, refreshAll: false);
                }
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
