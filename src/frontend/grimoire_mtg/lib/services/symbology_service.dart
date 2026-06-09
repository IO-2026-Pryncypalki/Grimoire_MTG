import 'package:flutter/foundation.dart';

import '../api/grimoire_api.dart';

class SymbologyService extends ChangeNotifier {
  final Map<String, String> _symbols = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  String? svgUri(String symbol) => _symbols[symbol];

  Future<void> load(GrimoireApi api) async {
    if (_loaded) return;
    try {
      final map = await api.getSymbology();
      _symbols
        ..clear()
        ..addAll(map);
      _loaded = true;
      notifyListeners();
    } catch (_) {
      // Symbology is cosmetic; silently tolerate failures.
    }
  }
}
