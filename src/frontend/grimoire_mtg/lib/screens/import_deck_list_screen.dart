import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../utils/sync_after_mutation.dart';
import '../widgets/content_width.dart';

class ImportDeckListScreen extends StatefulWidget {
  const ImportDeckListScreen({super.key, required this.deckId});

  final String deckId;

  @override
  State<ImportDeckListScreen> createState() => _ImportDeckListScreenState();
}

class _ImportDeckListScreenState extends State<ImportDeckListScreen> {
  final _textController = TextEditingController();
  String _mode = 'merge';
  bool _importing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<bool> _confirmReplace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.importReplaceConfirm),
          content: Text(l10n.importReplaceBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonReplace)),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _showResultDialog(ImportDeckListResultDto result) async {
    final l10n = context.l10n;
    final body = StringBuffer();
    body.writeln(l10n.importImportedCount(result.imported.length));
    if (result.clearedExisting) {
      body.writeln(l10n.importClearedExisting);
    }
    if (result.failed.isNotEmpty) {
      body.writeln();
      body.writeln(l10n.importUnrecognized(result.failed.length));
      for (final failure in result.failed.take(20)) {
        final line = failure.line != null ? l10n.importUnrecognizedLine(failure.line!) : '';
        body.writeln('• ${failure.name}$line');
      }
      if (result.failed.length > 20) {
        body.writeln(l10n.importAndMore(result.failed.length - 20));
      }
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.importComplete),
          content: SingleChildScrollView(child: Text(body.toString().trim())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.commonOK)),
          ],
        );
      },
    );
  }

  Future<void> _import() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.importPasteRequired)),
      );
      return;
    }

    if (_mode == 'replace') {
      final confirmed = await _confirmReplace();
      if (!confirmed) return;
    }

    setState(() => _importing = true);
    try {
      final result = await context.read<AuthService>().api.importDeckList(
            deckId: widget.deckId,
            text: text,
            mode: _mode,
          );
      await syncAfterLocalMutation(
        context,
        decks: true,
        deckId: widget.deckId,
        refreshAll: false,
      );
      if (!mounted) return;
      await _showResultDialog(result);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importTitle),
        actions: [
          TextButton(
            onPressed: _importing ? null : _import,
            child: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.importAction),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'merge', label: Text(l10n.importMerge)),
                  ButtonSegment(value: 'replace', label: Text(l10n.importReplace)),
                ],
                selected: {_mode},
                onSelectionChanged: _importing
                    ? null
                    : (selection) => setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 12),
              Text(l10n.importHint),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !_importing,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '1 Sol Ring\n1 Plains\n\n// Commander\n1 Atraxa, Praetors\' Voice',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              if (_importing) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.importRecognizing)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
