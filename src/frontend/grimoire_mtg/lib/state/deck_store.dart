import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';

class DeckStore extends ChangeNotifier {
  DeckStore(this._auth);

  AuthService _auth;

  List<DeckListItem> decks = [];
  bool loading = false;
  bool refreshing = false;
  String? error;
  DateTime? lastFetchedAt;

  void updateAuth(AuthService auth) {
    _auth = auth;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    await _fetch();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    if (silent && decks.isNotEmpty) {
      refreshing = true;
      notifyListeners();
    } else {
      loading = true;
      error = null;
      notifyListeners();
    }
    await _fetch();
    loading = false;
    refreshing = false;
    notifyListeners();
  }

  Future<void> refreshIfStale({Duration maxAge = const Duration(seconds: 30)}) async {
    if (lastFetchedAt != null &&
        DateTime.now().difference(lastFetchedAt!) < maxAge) {
      return;
    }
    await refresh(silent: decks.isNotEmpty);
  }

  void clear() {
    decks = [];
    loading = false;
    refreshing = false;
    error = null;
    lastFetchedAt = null;
    notifyListeners();
  }

  Future<void> _fetch() async {
    try {
      decks = await _auth.api.listDecks();
      error = null;
      lastFetchedAt = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    }
  }
}
