import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../l10n/app_localizations.dart';
import '../models/card.dart';
import '../models/collection.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../utils/deck_board_layout.dart';
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
  bool _loadingAvailability = true;
  CardAvailabilityDto? _availability;

  late final Map<String, int> _assignQtyByEntryId;

  List<CollectionEntryDto> get _validEntries => (widget.collectionEntries ?? [])
      .where((e) => e.collectionEntryId != null && e.collectionEntryId!.isNotEmpty)
      .toList();

  bool get _enforceCollectionLimit => _availability?.enforceCollectionLimit ?? false;

  int get _availableToAssign => _availability?.availableToAdd ?? 0;

  @override
  void initState() {
    super.initState();
    _assignQtyByEntryId = {
      for (final e in _validEntries) e.collectionEntryId!: 0,
    };
    if (_validEntries.length == 1) {
      _assignQtyByEntryId[_validEntries.first.collectionEntryId!] = 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailability());
  }

  Future<void> _loadAvailability() async {
    try {
      final availability = await context
          .read<AuthService>()
          .api
          .getCardAvailability(widget.card.scryfallId);
      if (!mounted) return;
      setState(() {
        _availability = availability;
        _loadingAvailability = false;
        _syncSingleEntryAssignment();
      });
    } on ApiException {
      if (mounted) {
        setState(() => _loadingAvailability = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingAvailability = false);
      }
    }
  }

  void _syncSingleEntryAssignment() {
    if (_validEntries.length != 1) return;
    final id = _validEntries.first.collectionEntryId!;
    final max = _validEntries.first.quantity;
    _assignQtyByEntryId[id] =
        _assignFromCollection ? _quantity.clamp(1, max) : 0;
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
    final l10n = context.l10n;
    if (_assignFromCollection && _assignedTotal > _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addToDeckExceedsQuantity)),
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

  String? _collectionSubtitle(AppLocalizations l10n) {
    if (_loadingAvailability) return null;
    if (!_enforceCollectionLimit) {
      if (_validEntries.isEmpty) return null;
      final total = _validEntries.fold(0, (sum, e) => sum + e.quantity);
      return l10n.addToDeckAvailableCopies(total);
    }
    if (_availableToAssign <= 0) {
      return l10n.addToDeckAllCopiesInDecks(_availability!.ownedQty);
    }
    return l10n.addToDeckAvailableToAdd(_availableToAssign);
  }

  Widget _buildDecksUsingList(AppLocalizations l10n) {
    final decksUsing = _availability?.decksUsing ?? [];
    if (decksUsing.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...decksUsing.map(
          (d) => Text(
            l10n.addToDeckUsedInDeck(d.quantity, d.deckName),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCollection = _validEntries.isNotEmpty;
    final collectionSubtitle = _collectionSubtitle(l10n);

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
              l10n.addToDeckTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.card.name != null)
              Text(widget.card.name!, style: Theme.of(context).textTheme.bodyMedium),
            if (_loadingAvailability) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(l10n.addToDeckQuantity),
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
              decoration: InputDecoration(
                labelText: l10n.deckBoardZone,
                border: const OutlineInputBorder(),
              ),
              items: deckBoards
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(deckBoardLabel(b, l10n)),
                    ),
                  )
                  .toList(),
              onChanged: _saving ? null : (v) => setState(() => _board = v ?? 'main'),
            ),
            if (hasCollection) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.addToDeckAssignFromCollection),
                subtitle: collectionSubtitle != null ? Text(collectionSubtitle) : null,
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
              if (_enforceCollectionLimit && (_availability?.decksUsing.isNotEmpty ?? false))
                _buildDecksUsingList(l10n),
              if (_assignFromCollection && _validEntries.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.deckAssignedCount(_assignedTotal, _quantity),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ..._validEntries.map(_buildEntryAssignmentRow),
              ],
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving || _loadingAvailability ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.addToDeckTitle),
            ),
          ],
        ),
      ),
    );
  }
}
