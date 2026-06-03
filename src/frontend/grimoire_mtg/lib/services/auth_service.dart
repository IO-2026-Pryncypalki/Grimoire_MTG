import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/http_client_factory.dart';
import '../api/api_exception.dart';
import '../api/grimoire_api.dart';
import '../config/env.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _client;
  late final GrimoireApi _api;
  bool _initialized = false;

  UserProfile? _user;
  bool _loading = true;
  String? _error;

  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;
  GrimoireApi get api => _api;

  Future<void> init() async {
    _client = ApiClient(
      getAccessToken: _getAccessToken,
      getRefreshToken: _getRefreshToken,
      saveTokens: _saveTokens,
      clearTokens: clearTokens,
      refreshSession: _refreshSession,
      useBearerAuth: !kIsWeb,
    );
    _api = GrimoireApi(_client);
    _initialized = true;
    await _restoreSession();
  }

  Future<String?> _getAccessToken() async {
    if (kIsWeb) return null;
    return _storage.read(key: _accessKey);
  }

  Future<String?> _getRefreshToken() async {
    if (kIsWeb) return null;
    return _storage.read(key: _refreshKey);
  }

  Future<void> _saveTokens(String access, String refresh) async {
    if (kIsWeb) return;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> clearTokens() async {
    if (!kIsWeb) {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    }
    _user = null;
    notifyListeners();
  }

  Future<bool> _refreshSession() async {
    if (kIsWeb) {
      try {
        final uri = Uri.parse('${Env.apiBaseUrl}/api/auth/refresh');
        final client = createHttpClient();
        final response = await client.post(
          uri,
          headers: {'Content-Type': 'application/json'},
        );
        client.close();
        return response.statusCode == 200;
      } catch (_) {
        return false;
      }
    }

    final refresh = await _getRefreshToken();
    if (refresh == null) return false;

    try {
      final uri = Uri.parse('${Env.apiBaseUrl}/api/auth/refresh/mobile');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
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

  Future<void> _restoreSession() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _api.getMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized && await _refreshSession()) {
        try {
          _user = await _api.getMe();
        } catch (_) {
          await clearTokens();
        }
      } else if (!e.isUnauthorized) {
        _error = e.message;
      } else {
        await clearTokens();
      }
    } catch (_) {
      await clearTokens();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
    await _restoreSession();
  }

  Future<void> logout() async {
    try {
      final refresh = await _getRefreshToken();
      await _api.logout(refreshToken: refresh);
    } catch (_) {}
    await clearTokens();
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
