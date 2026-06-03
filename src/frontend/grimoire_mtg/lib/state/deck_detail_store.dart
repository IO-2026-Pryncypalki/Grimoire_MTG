import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';

class DeckDetailStore extends ChangeNotifier {
  DeckDetailStore(this._auth);

  AuthService _auth;

  final Map<String, DeckDetails> _decks = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  void updateAuth(AuthService auth) {
    _auth = auth;
  }

  DeckDetails? deckFor(String deckId) => _decks[deckId];

  bool isLoading(String deckId) => _loading[deckId] ?? false;

  String? errorFor(String deckId) => _errors[deckId];

  Future<void> load(String deckId) async {
    _loading[deckId] = true;
    _errors[deckId] = null;
    notifyListeners();
    await _fetch(deckId);
    _loading[deckId] = false;
    notifyListeners();
  }

  Future<void> refresh(String deckId, {bool silent = false}) async {
    if (!silent || !_decks.containsKey(deckId)) {
      _loading[deckId] = true;
      _errors[deckId] = null;
      notifyListeners();
    }
    await _fetch(deckId);
    _loading[deckId] = false;
    notifyListeners();
  }

  void clear() {
    _decks.clear();
    _loading.clear();
    _errors.clear();
    notifyListeners();
  }

  Future<void> _fetch(String deckId) async {
    try {
      _decks[deckId] = await _auth.api.getDeck(deckId);
      _errors[deckId] = null;
    } on ApiException catch (e) {
      _errors[deckId] = e.message;
    }
  }
}
