import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/sync_status.dart';
import '../state/collection_store.dart';
import '../state/deck_detail_store.dart';
import '../state/deck_store.dart';
import 'auth_service.dart';
import 'realtime_sync_client.dart';
import 'visibility_listener.dart';

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
    _realtime = RealtimeSyncClient(
      getAccessToken: _auth.getAccessToken,
      onStatus: _onRealtimeStatus,
    );
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    listenForVisibility(_onVisibilityChanged);
    _onAuthChanged();
  }

  static const _pollIntervalConnected = Duration(seconds: 10);
  static const _pollIntervalDisconnected = Duration(seconds: 5);

  final AuthService _auth;
  final CollectionStore _collectionStore;
  final DeckStore _deckStore;
  final DeckDetailStore _deckDetailStore;

  late final RealtimeSyncClient _realtime;

  Timer? _timer;
  bool _foreground = true;
  String? _lastCollectionUpdatedAt;
  String? _lastDecksUpdatedAt;
  String? _activeDeckId;

  bool get isRealtimeConnected => _realtime.isConnected;

  void setActiveDeckId(String? deckId) {
    _activeDeckId = deckId;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      unawaited(_reconnectRealtime());
      unawaited(forceSync());
      _startPolling();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _stopPolling();
      unawaited(_realtime.disconnect());
    }
  }

  void _onVisibilityChanged(bool visible) {
    if (visible && _auth.isAuthenticated) {
      _foreground = true;
      unawaited(_reconnectRealtime());
      unawaited(forceSync());
      _startPolling();
    } else if (!visible) {
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
    await _seedFromServer();
    await _reconnectRealtime();
  }

  Future<void> forceSync() async {
    await _pollOnce(force: true);
  }

  Future<void> markSyncedAfterLocalWrite() async {
    await _seedFromServer();
  }

  Future<void> applyLocalMutation({
    bool collection = false,
    bool decks = false,
    String? deckId,
    bool refreshAll = false,
  }) async {
    final futures = <Future<void>>[];

    if (refreshAll || collection) {
      if (_collectionStore.data != null) {
        futures.add(_collectionStore.refresh(silent: true));
      } else if (!_collectionStore.loading) {
        futures.add(_collectionStore.load());
      }
    }
    if (refreshAll || decks) {
      if (_deckStore.decks.isNotEmpty) {
        futures.add(_deckStore.refresh(silent: true));
      } else if (!_deckStore.loading) {
        futures.add(_deckStore.load());
      }
      final id = deckId ?? _activeDeckId;
      if (id != null) {
        if (_deckDetailStore.deckFor(id) != null) {
          futures.add(_deckDetailStore.refresh(id, silent: true));
        } else if (!_deckDetailStore.isLoading(id)) {
          futures.add(_deckDetailStore.load(id));
        }
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    await _auth.reloadProfile();
    await markSyncedAfterLocalWrite();
    notifyListeners();
  }

  Future<void> _seedFromServer() async {
    try {
      final status = await _auth.api.getSyncStatus();
      _applyStatus(status);
    } catch (_) {}
  }

  void _onAuthChanged() {
    if (_auth.isLoading) return;

    if (_auth.isAuthenticated) {
      _resetTokens();
      unawaited(_bootstrapAfterAuth());
      _startPolling();
    } else {
      _stopPolling();
      unawaited(_realtime.disconnect());
      _resetTokens();
      _collectionStore.clear();
      _deckStore.clear();
      _deckDetailStore.clear();
    }
  }

  void _resetTokens() {
    _lastCollectionUpdatedAt = null;
    _lastDecksUpdatedAt = null;
  }

  void _applyStatus(SyncStatus status) {
    _lastCollectionUpdatedAt = status.collectionUpdatedAt;
    _lastDecksUpdatedAt = status.decksUpdatedAt;
  }

  void _onRealtimeStatus(SyncStatus status) {
    if (!_auth.isAuthenticated || !_foreground) return;
    unawaited(_applyRemoteChanges(status));
  }

  Future<void> _reconnectRealtime() async {
    if (!_auth.isAuthenticated) return;
    await _realtime.connect();
    _startPolling();
  }

  void _startPolling() {
    _stopPolling();
    if (!_auth.isAuthenticated || !_foreground) return;
    final interval =
        _realtime.isConnected ? _pollIntervalConnected : _pollIntervalDisconnected;
    _timer = Timer.periodic(interval, (_) => _pollOnce());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pollOnce({bool force = false}) async {
    if (!_auth.isAuthenticated || !_foreground) return;

    try {
      final status = await _auth.api.getSyncStatus();
      await _applyRemoteChanges(status, force: force);
    } catch (_) {
      // Keep stale data; retry on next interval.
    }
  }

  Future<void> _applyRemoteChanges(SyncStatus status, {bool force = false}) async {
    final collectionChanged = force ||
        _lastCollectionUpdatedAt == null ||
        status.collectionUpdatedAt != _lastCollectionUpdatedAt;
    final decksChanged = force ||
        _lastDecksUpdatedAt == null ||
        status.decksUpdatedAt != _lastDecksUpdatedAt;

    if (!collectionChanged && !decksChanged) return;

    final futures = <Future<void>>[];

    if (collectionChanged || decksChanged) {
      if (_collectionStore.data != null) {
        futures.add(_collectionStore.refresh(silent: true));
      }
    }
    if (decksChanged) {
      if (_deckStore.decks.isNotEmpty) {
        futures.add(_deckStore.refresh(silent: true));
      }
      if (_activeDeckId != null) {
        futures.add(_deckDetailStore.refresh(_activeDeckId!, silent: true));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
    if (collectionChanged || decksChanged) {
      await _auth.reloadProfile();
    }

    _applyStatus(status);
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    disposeVisibilityListener();
    _stopPolling();
    unawaited(_realtime.dispose());
    super.dispose();
  }
}
