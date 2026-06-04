import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'navigation/route_observer.dart';
import 'screens/collection_overview_screen.dart';
import 'screens/create_deck_screen.dart';
import 'screens/deck_overview_screen.dart';
import 'screens/first_tab_screen.dart';
import 'screens/user_profile_screen.dart';
import 'state/collection_store.dart';
import 'state/deck_store.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'utils/responsive.dart';

class MTGManagerApp extends StatelessWidget {
  const MTGManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grimoire MTG',
      debugShowCheckedModeBanner: false,
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

  late final List<NavigationDestination> _destinations;
  late final List<NavigationRailDestination> _railDestinations;

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

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _destinations = const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Szukaj'),
        NavigationDestination(icon: Icon(Icons.grid_view), label: 'Kolekcja'),
        NavigationDestination(icon: Icon(Icons.layers), label: 'Talie'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
      _railDestinations = const [
        NavigationRailDestination(icon: Icon(Icons.search), label: Text('Szukaj')),
        NavigationRailDestination(icon: Icon(Icons.grid_view), label: Text('Kolekcja')),
        NavigationRailDestination(icon: Icon(Icons.layers), label: Text('Talie')),
        NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profil')),
      ];
    } else {
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.document_scanner_rounded),
          label: 'Skaner',
        ),
        NavigationDestination(icon: Icon(Icons.grid_view), label: 'Kolekcja'),
        NavigationDestination(icon: Icon(Icons.layers), label: 'Talie'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
      _railDestinations = const [
        NavigationRailDestination(
          icon: Icon(Icons.document_scanner_rounded),
          label: Text('Skaner'),
        ),
        NavigationRailDestination(icon: Icon(Icons.grid_view), label: Text('Kolekcja')),
        NavigationRailDestination(icon: Icon(Icons.layers), label: Text('Talie')),
        NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profil')),
      ];
    }
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
    final useRail = context.isMediumUp;
    final body = _buildBody();

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: _railDestinations,
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
        destinations: _destinations,
      ),
    );
  }
}
