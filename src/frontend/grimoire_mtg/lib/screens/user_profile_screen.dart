import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Użytkownika')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            const Text('Nazwa Użytkownika', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Ustawienia')),
            ListTile(leading: const Icon(Icons.history), title: const Text('Historia skanowania')),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Wyloguj')),
          ],
        ),
      ),
    );
  }
}