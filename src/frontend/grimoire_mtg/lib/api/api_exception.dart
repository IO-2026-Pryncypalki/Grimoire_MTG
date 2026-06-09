import '../l10n/app_localizations.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

String messageFromResponse(
  int statusCode,
  Map<String, dynamic>? body,
  AppLocalizations l10n,
) {
  if (body == null) {
    if (statusCode == 429) return l10n.errorScryfallRateLimit;
    if (statusCode == 401) return l10n.errorSessionExpired;
    return l10n.errorServer(statusCode);
  }
  final msg = body['message'] ?? body['error'];
  if (msg is String && msg.isNotEmpty) {
    if (msg == 'Exceeds owned collection quantity') {
      return l10n.addToDeckExceedsOwnedQuantity;
    }
    return msg;
  }
  if (statusCode == 429) return l10n.errorScryfallRateLimit;
  return l10n.errorServer(statusCode);
}
