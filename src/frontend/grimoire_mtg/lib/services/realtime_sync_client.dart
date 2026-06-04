import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import '../models/sync_status.dart';

typedef AccessTokenProvider = Future<String?> Function();
typedef SyncStatusHandler = void Function(SyncStatus status);

class RealtimeSyncClient {
  RealtimeSyncClient({
    required this.getAccessToken,
    required this.onStatus,
  });

  final AccessTokenProvider getAccessToken;
  final SyncStatusHandler onStatus;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;
  int _backoffSeconds = 1;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_disposed) return;
    await disconnect();

    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final channel = WebSocketChannel.connect(Env.syncStreamUri(token));
      _channel = channel;
      _connected = true;
      _backoffSeconds = 1;

      _subscription = channel.stream.listen(
        _onMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final text = message is String ? message : utf8.decode(message as List<int>);
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (json['type'] != 'sync') return;
      onStatus(SyncStatus.fromJson(json));
    } catch (_) {
      // Ignore malformed push payloads.
    }
  }

  void _handleDisconnect() {
    _connected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _backoffSeconds), () {
      if (_disposed) return;
      _backoffSeconds = (_backoffSeconds * 2).clamp(1, 30);
      unawaited(connect());
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
  }
}
