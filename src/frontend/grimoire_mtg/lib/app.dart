import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'navigation/route_observer.dart';
import 'screens/collection_overview_screen.dart';
import 'screens/create_deck_screen.dart';
import 'screens/deck_overview_screen.dart';
import 'screens/first_tab_screen.dart';
import 'screens/user_profile_screen.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/sync_service.dart';
import 'state/collection_store.dart';
import 'state/deck_store.dart';
import 'utils/responsive.dart';

class MTGManagerApp extends StatelessWidget {
  const MTGManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();

    return MaterialApp(
      title: 'Grimoire MTG',
      debugShowCheckedModeBanner: false,
      locale: localeService.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(child: MainNavigationHandler()),
      navigatorObservers: [appRouteObserver],
      routes: {
        '/create-deck': (context) => const CreateDeckScreen(),
      },
    );
  }
}

class MainNavigationHandler extends StatefulWidget {
  const MainNavigationHandler({super.key});

  @override
  State<MainNavigationHandler> createState() => _MainNavigationHandlerState();
}

class _MainNavigationHandlerState extends State<MainNavigationHandler> {
  int _currentIndex = 0;

  static const _scannerTabIndex = 0;
  static const _collectionTabIndex = 1;
  static const _decksTabIndex = 2;
  static const _profileTabIndex = 3;

  static const _webScreens = [
    FirstTabScreen(),
    CollectionOverviewScreen(),
    DeckOverviewScreen(),
    UserProfileScreen(),
  ];

  static const _mobileDataScreens = [
    CollectionOverviewScreen(),
    DeckOverviewScreen(),
    UserProfileScreen(),
  ];

  List<NavigationDestination> _buildDestinations(AppLocalizations l10n) {
    if (kIsWeb) {
      return [
        NavigationDestination(icon: const Icon(Icons.search), label: l10n.navSearch),
        NavigationDestination(icon: const Icon(Icons.grid_view), label: l10n.navCollection),
        NavigationDestination(icon: const Icon(Icons.layers), label: l10n.navDecks),
        NavigationDestination(icon: const Icon(Icons.person), label: l10n.navProfile),
      ];
    }
    return [
      NavigationDestination(
        icon: const Icon(Icons.document_scanner_rounded),
        label: l10n.navScanner,
      ),
      NavigationDestination(icon: const Icon(Icons.grid_view), label: l10n.navCollection),
      NavigationDestination(icon: const Icon(Icons.layers), label: l10n.navDecks),
      NavigationDestination(icon: const Icon(Icons.person), label: l10n.navProfile),
    ];
  }

  List<NavigationRailDestination> _buildRailDestinations(AppLocalizations l10n) {
    if (kIsWeb) {
      return [
        NavigationRailDestination(icon: const Icon(Icons.search), label: Text(l10n.navSearch)),
        NavigationRailDestination(icon: const Icon(Icons.grid_view), label: Text(l10n.navCollection)),
        NavigationRailDestination(icon: const Icon(Icons.layers), label: Text(l10n.navDecks)),
        NavigationRailDestination(icon: const Icon(Icons.person), label: Text(l10n.navProfile)),
      ];
    }
    return [
      NavigationRailDestination(
        icon: const Icon(Icons.document_scanner_rounded),
        label: Text(l10n.navScanner),
      ),
      NavigationRailDestination(icon: const Icon(Icons.grid_view), label: Text(l10n.navCollection)),
      NavigationRailDestination(icon: const Icon(Icons.layers), label: Text(l10n.navDecks)),
      NavigationRailDestination(icon: const Icon(Icons.person), label: Text(l10n.navProfile)),
    ];
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == _collectionTabIndex) {
      final store = context.read<CollectionStore>();
      if (store.data == null && !store.loading) {
        store.load();
      } else {
        unawaited(context.read<SyncService>().forceSync());
      }
    } else if (index == _decksTabIndex) {
      final deckStore = context.read<DeckStore>();
      if (deckStore.decks.isEmpty && !deckStore.loading) {
        deckStore.load();
      } else {
        unawaited(context.read<SyncService>().forceSync());
      }
    } else if (index == _profileTabIndex) {
      context.read<AuthService>().reloadProfile();
    }
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return IndexedStack(
        index: _currentIndex,
        children: _webScreens,
      );
    }

    if (_currentIndex == _scannerTabIndex) {
      return const FirstTabScreen();
    }

    return IndexedStack(
      index: _currentIndex - 1,
      children: _mobileDataScreens,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final useRail = context.isMediumUp;
    final body = _buildBody();
    final destinations = _buildDestinations(l10n);
    final railDestinations = _buildRailDestinations(l10n);

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: railDestinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: destinations,
      ),
    );
  }
}
