import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/grimoire_api.dart';
import '../api/http_client_factory.dart';
import '../config/env.dart';
import '../models/user.dart';
import '../storage/session_token_storage.dart';

class AuthService extends ChangeNotifier {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final ApiClient _client;
  late final GrimoireApi _api;
  bool _initialized = false;
  bool _initComplete = false;

  UserProfile? _user;
  bool _loading = true;
  String? _error;
  bool _hasStoredSession = false;

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasStoredSession => _hasStoredSession;
  bool get canRetryRestore =>
      !isAuthenticated && _hasStoredSession && !_loading;
  GrimoireApi get api => _api;

  Future<String?> getAccessToken() => _getAccessToken();

  Future<void> init() async {
    if (_initComplete) return;

    if (kIsWeb) {
      SessionTokenStorage.consumeUrlTokensIfPresent();
    }

    _client = ApiClient(
      getAccessToken: _getAccessToken,
      getRefreshToken: _getRefreshToken,
      saveTokens: _saveTokens,
      clearTokens: clearTokens,
      refreshSession: _refreshSession,
      useBearerAuth: true,
    );
    _api = GrimoireApi(_client);
    _initialized = true;
    await _restoreSession();
    _initComplete = true;
  }

  Future<String?> _getAccessToken() async {
    if (kIsWeb) {
      return SessionTokenStorage.readAccess();
    }
    return _storage.read(key: _accessKey);
  }

  Future<String?> _getRefreshToken() async {
    if (kIsWeb) {
      return SessionTokenStorage.readRefresh();
    }
    return _storage.read(key: _refreshKey);
  }

  Future<bool> _readHasStoredSession() async {
    final refresh = await _getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) return true;
    final access = await _getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    if (kIsWeb) {
      await SessionTokenStorage.write(access, refresh);
    } else {
      await _storage.write(key: _accessKey, value: access);
      await _storage.write(key: _refreshKey, value: refresh);
    }
    _hasStoredSession = true;
  }

  Future<void> clearTokens() async {
    if (kIsWeb) {
      await SessionTokenStorage.clear();
    } else {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    }
    _user = null;
    _hasStoredSession = false;
    notifyListeners();
  }

  Future<bool> _refreshSession() async {
    final refresh = await _getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final uri = Uri.parse('${Env.apiBaseUrl}/api/auth/refresh/mobile');
      final client = kIsWeb ? createHttpClient() : http.Client();
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (kIsWeb) {
        client.close();
      }
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final access = body['accessToken'] as String?;
      final newRefresh = body['refreshToken'] as String?;
      if (access == null || newRefresh == null) return false;
      await _saveTokens(access, newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureAccessTokenFromRefresh() async {
    final access = await _getAccessToken();
    if (access != null && access.isNotEmpty) return;

    final refresh = await _getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      await _refreshSession();
    }
  }

  bool _isTransientFailure(Object error) {
    if (error is ApiException) {
      return error.statusCode >= 500;
    }
    return error is SocketException ||
        error is HttpException ||
        error is http.ClientException ||
        error is IOException ||
        error is FormatException;
  }

  void _setTransientError(Object error) {
    if (error is ApiException) {
      _error = error.message;
    } else {
      _error = 'Brak połączenia z serwerem. Sprawdź sieć i spróbuj ponownie.';
    }
  }

  Future<void> _restoreSession() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _hasStoredSession = await _readHasStoredSession();
      if (!_hasStoredSession) {
        _user = null;
        return;
      }

      await _ensureAccessTokenFromRefresh();
      _user = await _api.getMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        if (await _refreshSession()) {
          try {
            _user = await _api.getMe();
          } catch (retryError) {
            if (_isTransientFailure(retryError)) {
              _setTransientError(retryError);
            } else {
              await clearTokens();
            }
          }
        } else if (_isTransientFailure(e)) {
          _setTransientError(e);
        } else {
          await clearTokens();
        }
      } else if (_isTransientFailure(e)) {
        _setTransientError(e);
      } else {
        _error = e.message;
      }
    } catch (e) {
      if (_isTransientFailure(e)) {
        _setTransientError(e);
      } else {
        await clearTokens();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retryRestoreSession() => _restoreSession();

  Future<void> login() async {
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final uri = Uri.parse(Env.googleAuthUrl);
        await launchUrl(uri, webOnlyWindowName: '_self');
        return;
      }

      final result = await FlutterWebAuth2.authenticate(
        url: Env.googleMobileAuthUrl,
        callbackUrlScheme: Env.mobileAuthScheme,
      );

      final callbackUri = Uri.parse(result);
      final access = callbackUri.queryParameters['accessToken'];
      final refresh = callbackUri.queryParameters['refreshToken'];

      if (access == null || refresh == null) {
        throw ApiException(401, 'Brak tokenów po logowaniu.');
      }

      await _saveTokens(access, refresh);
      _user = await _api.getMe();
      _loading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkSessionAfterWebRedirect() async {
    SessionTokenStorage.consumeUrlTokensIfPresent();
    await _restoreSession();
  }

  Future<void> logout() async {
    try {
      final refresh = await _getRefreshToken();
      await _api.logout(refreshToken: refresh);
    } catch (_) {}
    await clearTokens();
    _loading = false;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    try {
      _user = await _api.getMe();
      notifyListeners();
    } catch (_) {
      // Keep existing profile on transient failures.
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _client.dispose();
    }
    super.dispose();
  }
}
