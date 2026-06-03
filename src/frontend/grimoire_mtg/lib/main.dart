import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'state/collection_store.dart';
import 'state/deck_detail_store.dart';
import 'state/deck_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProxyProvider<AuthService, CollectionStore>(
          create: (context) => CollectionStore(context.read<AuthService>()),
          update: (context, auth, store) => store!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, DeckStore>(
          create: (context) => DeckStore(context.read<AuthService>()),
          update: (context, auth, store) => store!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, DeckDetailStore>(
          create: (context) => DeckDetailStore(context.read<AuthService>()),
          update: (context, auth, store) => store!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider3<AuthService, CollectionStore, DeckStore,
            SyncService>(
          create: (context) => SyncService(
            auth: context.read<AuthService>(),
            collectionStore: context.read<CollectionStore>(),
            deckStore: context.read<DeckStore>(),
            deckDetailStore: context.read<DeckDetailStore>(),
          ),
          update: (context, auth, collection, deck, sync) => sync!,
        ),
      ],
      child: const MTGManagerApp(),
    ),
  );
}
