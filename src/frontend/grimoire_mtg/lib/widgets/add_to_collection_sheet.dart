import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/l10n_ext.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import '../utils/responsive.dart';
import '../utils/sync_after_mutation.dart';
import 'condition_selector.dart';
import 'content_width.dart';

Future<bool?> showAddToCollection(
  BuildContext context, {
  required String scryfallId,
  String? initialName,
}) {
  final sheet = AddToCollectionSheet(
    scryfallId: scryfallId,
    initialName: initialName,
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

class AddToCollectionSheet extends StatefulWidget {
  const AddToCollectionSheet({
    super.key,
    required this.scryfallId,
    this.initialName,
  });

  final String scryfallId;
  final String? initialName;

  @override
  State<AddToCollectionSheet> createState() => _AddToCollectionSheetState();
}

class _AddToCollectionSheetState extends State<AddToCollectionSheet> {
  int _quantity = 1;
  String _condition = 'NM';
  bool _isFoil = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().api.addToCollection(
            scryfallId: widget.scryfallId,
            quantity: _quantity,
            condition: _condition,
            isFoil: _isFoil,
          );
      await syncAfterLocalMutation(context, collection: true, refreshAll: false);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addToCollectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.initialName != null)
            Text(widget.initialName!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(l10n.addToCollectionQuantity),
              IconButton(
                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text('$_quantity'),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          ConditionSelector(value: _condition, onChanged: (v) => setState(() => _condition = v)),
          SwitchListTile(
            title: const Text('Foil'),
            value: _isFoil,
            onChanged: (v) => setState(() => _isFoil = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonAdd),
          ),
        ],
      ),
    );
  }
}
