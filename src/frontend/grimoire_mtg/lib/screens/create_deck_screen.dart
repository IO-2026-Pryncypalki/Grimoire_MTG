import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../services/auth_service.dart';
import '../state/deck_store.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nowa Talia'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ZAPISZ'),
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
              decoration: const InputDecoration(
                labelText: 'Nazwa talii',
                border: OutlineInputBorder(),
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
              decoration: const InputDecoration(
                labelText: 'Opis (opcjonalnie)',
                border: OutlineInputBorder(),
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
