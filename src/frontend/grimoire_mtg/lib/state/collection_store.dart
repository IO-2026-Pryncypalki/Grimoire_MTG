import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../models/collection.dart';
import '../services/auth_service.dart';

class CollectionStore extends ChangeNotifier {
  CollectionStore(this._auth);

  AuthService _auth;

  CollectionResponse? data;
  bool loading = false;
  bool refreshing = false;
  String? error;
  CollectionFilters filters = CollectionFilters();
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
    if (silent && data != null) {
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
    await refresh(silent: data != null);
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
    notifyListeners();
  }

  Future<void> _fetch() async {
    try {
      data = await _auth.api.getCollection(filters);
      error = null;
      lastFetchedAt = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    }
  }
}
