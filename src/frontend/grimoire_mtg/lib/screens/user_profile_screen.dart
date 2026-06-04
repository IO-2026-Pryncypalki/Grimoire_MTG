import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../services/auth_service.dart';
import '../widgets/content_width.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _usernameController = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    try {
      await context.read<AuthService>().api.updateUsername(_usernameController.text.trim());
      await context.read<AuthService>().reloadProfile();
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil zaktualizowany')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć konto?'),
        content: const Text('Tej operacji nie można cofnąć.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<AuthService>().api.deleteAccount();
      await context.read<AuthService>().logout();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    if (user != null && !_editing && _usernameController.text.isEmpty) {
      _usernameController.text = user.username;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Użytkownika')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ContentWidth(
              maxWidth: 480,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
                  const SizedBox(height: 16),
                  if (_editing)
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa użytkownika',
                        border: OutlineInputBorder(),
                      ),
                    )
                  else
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  Text(user.email),
                  const SizedBox(height: 8),
                  Text(
                    'Dołączono: ${user.stats.joinedAt}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.layers),
                    title: const Text('Talie'),
                    trailing: Text('${user.stats.deckCount}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.style),
                    title: const Text('Unikalne karty'),
                    trailing: Text('${user.stats.uniqueCardsCount}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: const Text('Fizyczne karty'),
                    trailing: Text('${user.stats.totalPhysicalCards}'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(_editing ? 'Zapisz nazwę' : 'Edytuj nazwę'),
                    onTap: () {
                      if (_editing) {
                        _saveUsername();
                      } else {
                        setState(() => _editing = true);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Wyloguj'),
                    onTap: () => auth.logout(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Usuń konto'),
                    onTap: _deleteAccount,
                  ),
                  ],
                ),
              ),
            ),
    );
  }
}
