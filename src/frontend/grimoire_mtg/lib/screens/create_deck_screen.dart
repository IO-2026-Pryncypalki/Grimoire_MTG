import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../services/auth_service.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/content_width.dart';
import '../widgets/deck_format_dropdown.dart';

class CreateDeckScreen extends StatefulWidget {
  const CreateDeckScreen({super.key});

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _format = 'Custom';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.createDeck(
            name: name,
            format: _format,
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
          );
      await syncAfterLocalMutation(context, decks: true, refreshAll: false);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deckNew),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.deckSave),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.deckName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DeckFormatDropdown(
              value: _format,
              onChanged: (v) => setState(() => _format = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: l10n.deckDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            ],
          ),
        ),
      ),
    );
  }
}
