import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../state/deck_detail_store.dart';
import '../state/deck_store.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import 'content_width.dart';

Future<bool?> showAddCardToDeckSheet(
  BuildContext context, {
  required String deckId,
  required CardDto card,
  List<CollectionEntryDto>? collectionEntries,
}) {
  final sheet = AddCardToDeckSheet(
    deckId: deckId,
    card: card,
    collectionEntries: collectionEntries,
  );

  if (context.isMediumUp) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: ContentWidth(
          maxWidth: 420,
          child: sheet,
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

class AddCardToDeckSheet extends StatefulWidget {
  const AddCardToDeckSheet({
    super.key,
    required this.deckId,
    required this.card,
    this.collectionEntries,
  });

  final String deckId;
  final CardDto card;
  final List<CollectionEntryDto>? collectionEntries;

  @override
  State<AddCardToDeckSheet> createState() => _AddCardToDeckSheetState();
}

class _AddCardToDeckSheetState extends State<AddCardToDeckSheet> {
  int _quantity = 1;
  String _board = 'main';
  bool _assignFromCollection = true;
  bool _saving = false;

  late final Map<String, int> _assignQtyByEntryId;

  List<CollectionEntryDto> get _validEntries => (widget.collectionEntries ?? [])
      .where((e) => e.collectionEntryId != null && e.collectionEntryId!.isNotEmpty)
      .toList();

  int get _maxCollectionCopies =>
      _validEntries.fold(0, (sum, e) => sum + e.quantity);

  @override
  void initState() {
    super.initState();
    _assignQtyByEntryId = {
      for (final e in _validEntries) e.collectionEntryId!: 0,
    };
    if (_validEntries.length == 1) {
      _assignQtyByEntryId[_validEntries.first.collectionEntryId!] = 1;
    }
  }

  void _syncSingleEntryAssignment() {
    if (_validEntries.length != 1) return;
    final id = _validEntries.first.collectionEntryId!;
    final max = _validEntries.first.quantity;
    _assignQtyByEntryId[id] = _assignFromCollection ? _quantity.clamp(1, max) : 0;
  }

  int get _assignedTotal =>
      _assignQtyByEntryId.values.fold(0, (sum, q) => sum + q);

  List<Map<String, dynamic>>? _buildAssignments() {
    if (!_assignFromCollection || _validEntries.isEmpty) return null;

    final assignments = <Map<String, dynamic>>[];
    for (final entry in _validEntries) {
      final id = entry.collectionEntryId!;
      final qty = _assignQtyByEntryId[id] ?? 0;
      if (qty > 0) {
        assignments.add({
          'collectionEntryId': id,
          'quantity': qty,
        });
      }
    }
    return assignments.isEmpty ? null : assignments;
  }

  Future<void> _save() async {
    if (_assignFromCollection && _assignedTotal > _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Przypisane kopie przekraczają ilość w talii')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.addCardToDeck(
            deckId: widget.deckId,
            scryfallId: widget.card.scryfallId,
            quantity: _quantity,
            board: _board,
            assignments: _buildAssignments(),
          );
      await syncAfterLocalMutation(
        context,
        collection: true,
        decks: true,
        deckId: widget.deckId,
        refreshAll: false,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildEntryAssignmentRow(CollectionEntryDto entry) {
    final id = entry.collectionEntryId!;
    final qty = _assignQtyByEntryId[id] ?? 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${entry.condition}${entry.isFoil ? ' ✨' : ''} (max ${entry.quantity})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton(
          onPressed: qty > 0
              ? () => setState(() {
                    _assignQtyByEntryId[id] = qty - 1;
                  })
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$qty'),
        IconButton(
          onPressed: qty < entry.quantity && _assignedTotal < _quantity
              ? () => setState(() {
                    _assignQtyByEntryId[id] = qty + 1;
                  })
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCollection = _validEntries.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dodaj do talii',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.card.name != null)
              Text(widget.card.name!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Ilość w talii:'),
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() {
                            _quantity--;
                            _syncSingleEntryAssignment();
                          })
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('$_quantity'),
                IconButton(
                  onPressed: () => setState(() {
                    _quantity++;
                    _syncSingleEntryAssignment();
                  }),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              value: _board,
              decoration: const InputDecoration(
                labelText: 'Strefa',
                border: OutlineInputBorder(),
              ),
              items: deckBoards
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(b),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _board = v ?? 'main'),
            ),
            if (hasCollection) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Przypisz z kolekcji'),
                subtitle: Text('Dostępne kopie: $_maxCollectionCopies'),
                value: _assignFromCollection,
                onChanged: _saving
                    ? null
                    : (v) => setState(() {
                          _assignFromCollection = v;
                          if (v && _validEntries.length == 1) {
                            _syncSingleEntryAssignment();
                          } else if (!v) {
                            for (final id in _assignQtyByEntryId.keys) {
                              _assignQtyByEntryId[id] = 0;
                            }
                          }
                        }),
              ),
              if (_assignFromCollection && _validEntries.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Przypisane: $_assignedTotal / $_quantity',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ..._validEntries.map(_buildEntryAssignmentRow),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Dodaj do talii'),
            ),
          ],
        ),
      ),
    );
  }
}
