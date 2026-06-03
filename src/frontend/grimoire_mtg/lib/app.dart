import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'screens/card_search_screen.dart';
import 'screens/collection_overview_screen.dart';
import 'screens/create_deck_screen.dart';
import 'screens/deck_overview_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/user_profile_screen.dart';
import 'state/collection_store.dart';
import 'state/deck_store.dart';
import 'services/auth_service.dart';

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

  late final List<Widget> _screens;
  late final List<NavigationDestination> _destinations;

  static const _collectionTabIndex = 1;
  static const _decksTabIndex = 2;
  static const _profileTabIndex = 3;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _screens = const [
        CardSearchScreen(),
        CollectionOverviewScreen(),
        DeckOverviewScreen(),
        UserProfileScreen(),
      ];
      _destinations = const [
        NavigationDestination(icon: Icon(Icons.search), label: 'Szukaj'),
        NavigationDestination(icon: Icon(Icons.grid_view), label: 'Kolekcja'),
        NavigationDestination(icon: Icon(Icons.layers), label: 'Talie'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      _screens = const [
        ScannerScreen(),
        CollectionOverviewScreen(),
        DeckOverviewScreen(),
        UserProfileScreen(),
      ];
      _destinations = const [
        NavigationDestination(
          icon: Icon(Icons.document_scanner_rounded),
          label: 'Skaner',
        ),
        NavigationDestination(icon: Icon(Icons.grid_view), label: 'Kolekcja'),
        NavigationDestination(icon: Icon(Icons.layers), label: 'Talie'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    if (index == _collectionTabIndex) {
      context.read<CollectionStore>().refreshIfStale();
    } else if (index == _decksTabIndex) {
      context.read<DeckStore>().refreshIfStale();
    } else if (index == _profileTabIndex) {
      context.read<AuthService>().reloadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
