import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import 'card_detail_screen.dart';

class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key, required this.entry});

  final CollectionEntryDto entry;

  @override
  State<CollectionEntryScreen> createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen> {
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _afterMutation() async {
    await context.read<CollectionStore>().refresh(silent: true);
    await context.read<AuthService>().reloadProfile();
  }

  Future<void> _updateDelta(int delta) async {
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.updateCollectionEntry(
            scryfallId: widget.entry.scryfallId,
            condition: widget.entry.condition,
            isFoil: widget.entry.isFoil,
            delta: delta,
          );
      await _afterMutation();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.updateCollectionEntry(
            scryfallId: widget.entry.scryfallId,
            condition: widget.entry.condition,
            isFoil: widget.entry.isFoil,
            notes: _notesController.text,
          );
      await _afterMutation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zapisano notatki')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć wpis?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Usuń')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<AuthService>().api.removeFromCollection(
            scryfallId: widget.entry.scryfallId,
            condition: widget.entry.condition,
            isFoil: widget.entry.isFoil,
          );
      await _afterMutation();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name ?? 'Wpis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _saving ? null : _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('${entry.setCode ?? ''} • x${entry.quantity}'),
            subtitle: Text('${entry.condition}${entry.isFoil ? ' • Foil' : ''}'),
          ),
          Row(
            children: [
              FilledButton(
                onPressed: _saving ? null : () => _updateDelta(1),
                child: const Text('+1'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving || entry.quantity <= 1
                    ? null
                    : () => _updateDelta(-1),
                child: const Text('-1'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CardDetailScreen(scryfallId: entry.scryfallId),
                  ),
                ),
                child: const Text('Szczegóły karty'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notatki',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _saveNotes,
            child: const Text('Zapisz notatki'),
          ),
        ],
      ),
    );
  }
}
