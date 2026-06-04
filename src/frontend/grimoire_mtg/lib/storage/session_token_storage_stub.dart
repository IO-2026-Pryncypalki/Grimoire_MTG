class SessionTokenStorage {
  static bool consumeUrlTokensIfPresent() => false;

  static Future<String?> readAccess() async => null;

  static Future<String?> readRefresh() async => null;

  static Future<void> write(String access, String refresh) async {}

  static Future<void> clear() async {}
}
