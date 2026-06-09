import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
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
          SnackBar(content: Text(context.l10n.profileUpdated)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteConfirm),
        content: Text(l10n.profileDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
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
    final localeService = context.watch<LocaleService>();
    final user = auth.user;
    final l10n = context.l10n;

    if (user != null && !_editing && _usernameController.text.isEmpty) {
      _usernameController.text = user.username;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
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
                      decoration: InputDecoration(
                        labelText: l10n.profileUsername,
                        border: const OutlineInputBorder(),
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
                    l10n.profileJoined(user.stats.joinedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.profileLanguage),
                    trailing: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'pl', label: Text('Polski')),
                        ButtonSegment(value: 'en', label: Text('English')),
                      ],
                      selected: {localeService.locale.languageCode},
                      onSelectionChanged: (selection) {
                        final code = selection.first;
                        localeService.setLocale(Locale(code));
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.layers),
                    title: Text(l10n.profileDecks),
                    trailing: Text('${user.stats.deckCount}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.style),
                    title: Text(l10n.profileUniqueCards),
                    trailing: Text('${user.stats.uniqueCardsCount}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy),
                    title: Text(l10n.profilePhysicalCards),
                    trailing: Text('${user.stats.totalPhysicalCards}'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: Text(_editing ? l10n.profileSaveName : l10n.profileEditName),
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
                    title: Text(l10n.profileLogout),
                    onTap: () => auth.logout(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(l10n.profileDeleteAccount),
                    onTap: _deleteAccount,
                  ),
                  ],
                ),
              ),
            ),
    );
  }
}
