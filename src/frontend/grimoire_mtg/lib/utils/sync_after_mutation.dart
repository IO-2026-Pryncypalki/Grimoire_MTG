import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';

Future<void> syncAfterLocalMutation(
  BuildContext context, {
  bool collection = false,
  bool decks = false,
  String? deckId,
  bool refreshAll = true,
}) {
  return context.read<SyncService>().applyLocalMutation(
        collection: collection,
        decks: decks,
        deckId: deckId,
        refreshAll: refreshAll,
      );
}
