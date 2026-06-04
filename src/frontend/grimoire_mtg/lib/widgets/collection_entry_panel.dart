import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../utils/sync_after_mutation.dart';

class CollectionEntryPanel extends StatefulWidget {
  const CollectionEntryPanel({
    super.key,
    required this.entry,
    this.onEntryRemoved,
  });

  final CollectionEntryDto entry;
  final VoidCallback? onEntryRemoved;

  @override
  State<CollectionEntryPanel> createState() => _CollectionEntryPanelState();
}

class _CollectionEntryPanelState extends State<CollectionEntryPanel> {
  late final TextEditingController _notesController;
  late int _quantity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.entry.quantity;
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _afterMutation() async {
    await syncAfterLocalMutation(context, collection: true, refreshAll: false);
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
      if (!mounted) return;

      final newQty = _quantity + delta;
      if (newQty <= 0) {
        widget.onEntryRemoved?.call();
      } else {
        setState(() => _quantity = newQty);
      }
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

    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.removeFromCollection(
            scryfallId: widget.entry.scryfallId,
            condition: widget.entry.condition,
            isFoil: widget.entry.isFoil,
          );
      await _afterMutation();
      if (mounted) widget.onEntryRemoved?.call();
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
    final entry = widget.entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Twoja kolekcja',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${entry.setCode ?? ''} • x$_quantity'),
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
              onPressed: _saving || _quantity <= 1 ? null : () => _updateDelta(-1),
              child: const Text('-1'),
            ),
            const Spacer(),
            TextButton(
              onPressed: _saving ? null : _delete,
              child: const Text('Usuń wpis'),
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
    );
  }
}
