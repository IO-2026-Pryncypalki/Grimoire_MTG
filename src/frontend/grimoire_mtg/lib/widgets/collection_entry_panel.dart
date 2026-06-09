import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../utils/sync_after_mutation.dart';
import 'condition_selector.dart';

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
  late String _targetCondition;
  int _transferQty = 1;
  bool _saving = false;

  List<CollectionEntryAssignmentDto>? _deckAssignments;
  bool _loadingAssignments = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.entry.quantity;
    _targetCondition = widget.entry.condition;
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    if (widget.entry.collectionEntryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeckAssignments());
    }
  }

  Future<void> _loadDeckAssignments() async {
    final entryId = widget.entry.collectionEntryId;
    if (entryId == null || !mounted) return;
    final api = context.read<AuthService>().api;
    setState(() => _loadingAssignments = true);
    try {
      final assignments = await api.getCollectionEntryAssignments(entryId);
      if (mounted) {
        setState(() {
          _deckAssignments = assignments;
          _loadingAssignments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAssignments = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _afterMutation() async {
    await syncAfterLocalMutation(context, collection: true, refreshAll: false);
  }

  Future<void> _transferCondition() async {
    final fromCondition = widget.entry.condition;
    if (_targetCondition == fromCondition || _transferQty < 1 || _transferQty > _quantity) {
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.transferCondition(
            scryfallId: widget.entry.scryfallId,
            fromCondition: fromCondition,
            toCondition: _targetCondition,
            isFoil: widget.entry.isFoil,
            quantity: _transferQty,
          );
      await _afterMutation();
      if (!mounted) return;

      final newQty = _quantity - _transferQty;
      if (newQty <= 0) {
        widget.onEntryRemoved?.call();
      } else {
        setState(() {
          _quantity = newQty;
          _transferQty = _transferQty > newQty ? newQty : _transferQty;
          _targetCondition = fromCondition;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.collectionConditionChanged)),
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

  bool get _canTransfer =>
      !_saving &&
      _targetCondition != widget.entry.condition &&
      _transferQty >= 1 &&
      _transferQty <= _quantity;

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
        setState(() {
          _quantity = newQty;
          if (_transferQty > newQty) _transferQty = newQty;
        });
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
          SnackBar(content: Text(context.l10n.collectionEntrySaveNotes)),
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
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.collectionEntryDeleteConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
          ],
        );
      },
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

  Widget _buildDeckUsageSection(AppLocalizations l10n, CollectionEntryDto entry) {
    if (_loadingAssignments) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    final assignments = _deckAssignments;
    if (assignments == null || (assignments.isEmpty)) {
      return const SizedBox.shrink();
    }

    final assignedTotal = assignments.fold<int>(0, (sum, a) => sum + a.quantity);
    final unassigned = _quantity - assignedTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.collectionEntryDeckUsage,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        ...assignments.map(
          (a) => Text(
            l10n.addToDeckUsedInDeck(a.quantity, a.deckName),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (unassigned > 0)
          Text(
            l10n.collectionEntryUnassigned(unassigned),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entry = widget.entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.collectionYourCollection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${entry.setCode ?? ''} • x$_quantity'),
          subtitle: Text('${entry.condition}${entry.isFoil ? ' • Foil' : ''}'),
        ),
        if (widget.entry.collectionEntryId != null) ...[
          _buildDeckUsageSection(l10n, entry),
          const SizedBox(height: 8),
        ],
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
              child: Text(l10n.collectionEntryDelete),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.collectionEntryChangeCondition,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ConditionSelector(
          value: _targetCondition,
          onChanged: (v) => setState(() => _targetCondition = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(l10n.collectionEntryQuantityToMove),
            IconButton(
              onPressed: _saving || _transferQty <= 1
                  ? null
                  : () => setState(() => _transferQty--),
              icon: const Icon(Icons.remove),
            ),
            Text('$_transferQty'),
            IconButton(
              onPressed: _saving || _transferQty >= _quantity
                  ? null
                  : () => setState(() => _transferQty++),
              icon: const Icon(Icons.add),
            ),
            const Spacer(),
            Text('max $_quantity'),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _canTransfer ? _transferCondition : null,
          child: Text(l10n.collectionEntryChangeCondition),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            labelText: l10n.collectionNotes,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _saveNotes,
          child: Text(l10n.collectionEntrySaveNotes),
        ),
      ],
    );
  }
}
