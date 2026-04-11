// Domyślnie używamy stuba (dla analizatora)
export 'text_scanner_stub.dart'
    // Jeśli kompilujemy na urządzenie (io), używamy mobile
    if (dart.library.io) 'text_scanner_mobile.dart'
    // Jeśli kompilujemy na web, używamy web
    if (dart.library.html) 'text_scanner_web.dart';