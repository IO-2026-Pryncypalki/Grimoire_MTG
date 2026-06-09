import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/symbology_service.dart';
import 'services/sync_service.dart';
import 'state/collection_store.dart';
import 'state/deck_detail_store.dart';
import 'state/deck_store.dart';

/// Provides app state after [AuthService.init] has completed.
class AppBootstrap extends StatelessWidget {
  const AppBootstrap({
    super.key,
    required this.auth,
    required this.localeService,
  });

  final AuthService auth;
  final LocaleService localeService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleService>.value(value: localeService),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProxyProvider<AuthService, CollectionStore>(
          create: (context) => CollectionStore(
            context.read<AuthService>(),
            context.read<LocaleService>(),
          ),
          update: (context, auth, store) =>
              store!..updateAuth(auth)..updateLocale(context.read<LocaleService>()),
        ),
        ChangeNotifierProxyProvider<AuthService, DeckStore>(
          create: (context) => DeckStore(
            context.read<AuthService>(),
            context.read<LocaleService>(),
          ),
          update: (context, auth, store) =>
              store!..updateAuth(auth)..updateLocale(context.read<LocaleService>()),
        ),
        ChangeNotifierProxyProvider<AuthService, DeckDetailStore>(
          create: (context) => DeckDetailStore(context.read<AuthService>()),
          update: (context, auth, store) => store!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthService, SymbologyService>(
          create: (_) => SymbologyService(),
          update: (context, auth, service) => service!..load(auth.api),
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
    );
  }
}
