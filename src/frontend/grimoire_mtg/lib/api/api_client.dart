import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'api_exception.dart';
import 'http_client_factory.dart';

typedef TokenProvider = Future<String?> Function();
typedef TokenSaver = Future<void> Function(String access, String refresh);
typedef OnUnauthorized = Future<bool> Function();

class ApiClient {
  ApiClient({
    required this.getAccessToken,
    required this.getRefreshToken,
    required this.saveTokens,
    required this.clearTokens,
    required this.refreshSession,
    this.useBearerAuth = true,
  });

  final Future<String?> Function() getAccessToken;
  final Future<String?> Function() getRefreshToken;
  final Future<void> Function(String access, String refresh) saveTokens;
  final Future<void> Function() clearTokens;
  final Future<bool> Function() refreshSession;
  final bool useBearerAuth;

  final http.Client _client = createHttpClient();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(Env.apiBaseUrl);
    return base.replace(
      path: path.startsWith('/') ? path : '/$path',
      queryParameters: query?.isNotEmpty == true ? query : null,
    );
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (useBearerAuth) {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, String>> _getHeaders() async {
    return _headers(json: false);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401 && await refreshSession()) {
      response = await request();
    }
    return response;
  }

  Map<String, dynamic>? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
      response.statusCode,
      messageFromResponse(response.statusCode, _decodeBody(response)),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () async => _client.get(_uri(path, query), headers: await _getHeaders()),
    );
    _throwIfError(response);
    final body = _decodeBody(response);
    return body ?? {};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () async => _client.post(
        _uri(path, query),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    _throwIfError(response);
    return _decodeBody(response) ?? {};
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () async => _client.patch(
        _uri(path, query),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    _throwIfError(response);
    return _decodeBody(response) ?? {};
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final response = await _send(
      () async => _client.delete(
        _uri(path, query),
        headers: await _headers(),
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    _throwIfError(response);
    return _decodeBody(response) ?? {};
  }

  void dispose() => _client.close();
}
