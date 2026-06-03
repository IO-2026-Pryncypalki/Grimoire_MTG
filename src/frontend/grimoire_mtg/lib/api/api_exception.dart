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

String messageFromResponse(int statusCode, Map<String, dynamic>? body) {
  if (body == null) {
    if (statusCode == 429) {
      return 'Limit Scryfall — spróbuj za chwilę.';
    }
    if (statusCode == 401) return 'Sesja wygasła. Zaloguj się ponownie.';
    return 'Błąd serwera ($statusCode).';
  }
  final msg = body['message'] ?? body['error'];
  if (msg is String && msg.isNotEmpty) return msg;
  if (statusCode == 429) return 'Limit Scryfall — spróbuj za chwilę.';
  return 'Błąd serwera ($statusCode).';
}
