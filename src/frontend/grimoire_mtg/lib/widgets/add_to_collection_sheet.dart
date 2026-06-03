import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../services/auth_service.dart';
import '../state/collection_store.dart';
import 'condition_selector.dart';

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
      await context.read<CollectionStore>().refresh(silent: true);
      await context.read<AuthService>().reloadProfile();
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
            'Dodaj do kolekcji',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (widget.initialName != null)
            Text(widget.initialName!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Ilość:'),
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
                : const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
}
