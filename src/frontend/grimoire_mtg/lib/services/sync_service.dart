import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/collection_store.dart';
import '../state/deck_detail_store.dart';
import '../state/deck_store.dart';
import 'auth_service.dart';

class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService({
    required AuthService auth,
    required CollectionStore collectionStore,
    required DeckStore deckStore,
    required DeckDetailStore deckDetailStore,
  })  : _auth = auth,
        _collectionStore = collectionStore,
        _deckStore = deckStore,
        _deckDetailStore = deckDetailStore {
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    _onAuthChanged();
  }

  static const _pollInterval = Duration(seconds: 5);

  final AuthService _auth;
  final CollectionStore _collectionStore;
  final DeckStore _deckStore;
  final DeckDetailStore _deckDetailStore;

  Timer? _timer;
  bool _foreground = true;
  String? _lastSyncToken;
  String? _lastCollectionUpdatedAt;
  String? _lastDecksUpdatedAt;
  String? _activeDeckId;

  void setActiveDeckId(String? deckId) {
    _activeDeckId = deckId;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      unawaited(forceSync());
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _stopPolling();
    }
  }

  Future<void> _bootstrapAfterAuth() async {
    final futures = <Future<void>>[];
    if (_collectionStore.data == null && !_collectionStore.loading) {
      futures.add(_collectionStore.load());
    }
    if (_deckStore.decks.isEmpty && !_deckStore.loading) {
      futures.add(_deckStore.load());
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    await _pollOnce(initialSeed: true);
  }

  Future<void> forceSync() async {
    await _pollOnce(initialSeed: _lastSyncToken == null);
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      _resetTokens();
      unawaited(_bootstrapAfterAuth());
      _startPolling();
    } else {
      _stopPolling();
      _resetTokens();
      _collectionStore.clear();
      _deckStore.clear();
      _deckDetailStore.clear();
    }
  }

  void _resetTokens() {
    _lastSyncToken = null;
    _lastCollectionUpdatedAt = null;
    _lastDecksUpdatedAt = null;
  }

  void _startPolling() {
    _stopPolling();
    if (!_auth.isAuthenticated || !_foreground) return;
    _timer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce({bool initialSeed = false}) async {
    if (!_auth.isAuthenticated || !_foreground) return;

    try {
      final status = await _auth.api.getSyncStatus();

      if (initialSeed || _lastSyncToken == null) {
        _lastSyncToken = status.syncToken;
        _lastCollectionUpdatedAt = status.collectionUpdatedAt;
        _lastDecksUpdatedAt = status.decksUpdatedAt;
        return;
      }

      if (status.syncToken == _lastSyncToken) return;

      final collectionChanged =
          status.collectionUpdatedAt != _lastCollectionUpdatedAt;
      final decksChanged = status.decksUpdatedAt != _lastDecksUpdatedAt;

      if (collectionChanged) {
        await _collectionStore.refresh(silent: true);
      }
      if (decksChanged) {
        await _deckStore.refresh(silent: true);
        if (_activeDeckId != null) {
          await _deckDetailStore.refresh(_activeDeckId!, silent: true);
        }
      }
      if (collectionChanged || decksChanged) {
        await _auth.reloadProfile();
      }

      _lastSyncToken = status.syncToken;
      _lastCollectionUpdatedAt = status.collectionUpdatedAt;
      _lastDecksUpdatedAt = status.decksUpdatedAt;
    } catch (_) {
      // Keep stale data; retry on next interval.
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }
}
