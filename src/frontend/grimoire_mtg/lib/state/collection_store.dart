import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';

class CollectionStore extends ChangeNotifier {
  CollectionStore(this._auth, this._localeService);

  AuthService _auth;
  LocaleService _localeService;
  Future<void>? _inFlight;

  CollectionResponse? data;
  bool loading = false;
  bool refreshing = false;
  String? error;
  CollectionFilters filters = CollectionFilters();
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
    if (silent && data != null) {
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
    if (data == null) {
      if (!loading) await load();
      return;
    }
    if (lastFetchedAt != null &&
        DateTime.now().difference(lastFetchedAt!) < maxAge) {
      return;
    }
    await refresh(silent: true);
  }

  void setFilters(CollectionFilters value) {
    filters = value;
  }

  Future<void> reloadWithFilters(CollectionFilters value) async {
    filters = value;
    await load();
  }

  void clear() {
    data = null;
    loading = false;
    refreshing = false;
    error = null;
    lastFetchedAt = null;
    _inFlight = null;
    notifyListeners();
  }

  Future<void> _fetch() async {
    try {
      data = await _auth.api.getCollection(filters);
      error = null;
      lastFetchedAt = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e, stack) {
      error = lookupAppLocalizations(_localeService.locale).errorLoadCollection;
      if (kDebugMode) {
        debugPrint('CollectionStore fetch failed: $e\n$stack');
      }
    }
  }
}
