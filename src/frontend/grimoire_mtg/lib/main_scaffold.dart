import 'package:flutter/material.dart';


import 'screens/user_profile_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/collection_overview_screen.dart';
import 'screens/deck_overview_screen.dart';
import 'screens/create_deck_screen.dart';

void main() {
  runApp(const MTGManagerApp());
}

class MTGManagerApp extends StatelessWidget {
  const MTGManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Scanner & Deck Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigationHandler(),
      // Rejestracja tras dla nawigacji dedykowanej (np. otwieranie kreatora talii)
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

  // Lista głównych widoków
  final List<Widget> _screens = [
    const ScannerScreen(),
    const CollectionOverviewScreen(),
    const DeckOverviewScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Skaner',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Kolekcja',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            label: 'Talie',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}