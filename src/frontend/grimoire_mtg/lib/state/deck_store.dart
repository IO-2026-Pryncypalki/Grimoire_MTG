import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../models/deck.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';

class DeckStore extends ChangeNotifier {
  DeckStore(this._auth, this._localeService);

  AuthService _auth;
  LocaleService _localeService;
  Future<void>? _inFlight;

  List<DeckListItem> decks = [];
  bool loading = false;
  bool refreshing = false;
  String? error;
  DateTime? lastFetchedAt;

  void updateAuth(AuthService auth) {
    _auth = auth;
  }

  void updateLocale(LocaleService localeService) {
    _localeService = localeService;
  }

  Future<void> load() async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }
    loading = true;
    error = null;
    notifyListeners();
    _inFlight = _fetch();
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (_inFlight != null) {
      await _inFlight;
      return;
    }
    if (silent && decks.isNotEmpty) {
      refreshing = true;
      notifyListeners();
    } else {
      loading = true;
      error = null;
      notifyListeners();
    }
    _inFlight = _fetch();
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
      loading = false;
      refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshIfStale({Duration maxAge = const Duration(seconds: 30)}) async {
    if (decks.isEmpty) {
      if (!loading) await load();
      return;
    }
    if (lastFetchedAt != null &&
        DateTime.now().difference(lastFetchedAt!) < maxAge) {
      return;
    }
    await refresh(silent: true);
  }

  void clear() {
    decks = [];
    loading = false;
    refreshing = false;
    error = null;
    lastFetchedAt = null;
    _inFlight = null;
    notifyListeners();
  }

  Future<void> _fetch() async {
    try {
      decks = await _auth.api.listDecks();
      error = null;
      lastFetchedAt = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e, stack) {
      error = lookupAppLocalizations(_localeService.locale).errorLoadDecks;
      if (kDebugMode) {
        debugPrint('DeckStore fetch failed: $e\n$stack');
      }
    }
  }
}
