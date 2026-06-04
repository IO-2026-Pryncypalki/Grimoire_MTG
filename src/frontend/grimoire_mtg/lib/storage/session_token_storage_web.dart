import 'dart:html' as html;

class SessionTokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static bool consumeUrlTokensIfPresent() {
    final hash = html.window.location.hash;
    if (hash.length <= 1) return false;

    final params = Uri.splitQueryString(hash.startsWith('#') ? hash.substring(1) : hash);
    final access = params['accessToken'];
    final refresh = params['refreshToken'];
    if (access == null || refresh == null || access.isEmpty || refresh.isEmpty) {
      return false;
    }

    html.window.sessionStorage[_accessKey] = access;
    html.window.sessionStorage[_refreshKey] = refresh;
    html.window.history.replaceState(
      null,
      '',
      '${html.window.location.pathname ?? ''}${html.window.location.search}',
    );
    return true;
  }

  static Future<String?> readAccess() async =>
      html.window.sessionStorage[_accessKey];

  static Future<String?> readRefresh() async =>
      html.window.sessionStorage[_refreshKey];

  static Future<void> write(String access, String refresh) async {
    html.window.sessionStorage[_accessKey] = access;
    html.window.sessionStorage[_refreshKey] = refresh;
  }

  static Future<void> clear() async {
    html.window.sessionStorage.remove(_accessKey);
    html.window.sessionStorage.remove(_refreshKey);
  }
}
