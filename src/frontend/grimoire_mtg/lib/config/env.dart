import 'package:flutter/foundation.dart';

class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String mobileAuthScheme = String.fromEnvironment(
    'MOBILE_AUTH_SCHEME',
    defaultValue: 'grimoire',
  );

  static String get googleAuthUrl => '$apiBaseUrl/api/auth/google';

  static String get googleMobileAuthUrl => '$apiBaseUrl/api/auth/google/mobile';

  static String get mobileAuthCallback => '$mobileAuthScheme://auth';

  static String get defaultApiHost {
    if (kIsWeb) return apiBaseUrl;
    return apiBaseUrl;
  }

  static Uri syncStreamUri(String accessToken) {
    final base = Uri.parse(apiBaseUrl);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      path: '/api/sync/stream',
      queryParameters: {'token': accessToken},
    );
  }
}
