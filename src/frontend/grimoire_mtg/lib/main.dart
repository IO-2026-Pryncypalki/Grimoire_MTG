import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localeService = LocaleService();
  await localeService.init();

  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      error.toString(),
      name: 'PlatformDispatcher',
      stackTrace: stack,
      error: error,
    );
    return false;
  };

  ErrorWidget.builder = (details) {
    final l10n = lookupAppLocalizations(localeService.locale);
    return Material(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.errorAppStartup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  final auth = AuthService(localeService: localeService);
  await auth.init();

  runApp(AppBootstrap(auth: auth, localeService: localeService));
}
