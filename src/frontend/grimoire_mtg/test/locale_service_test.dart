import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grimoire_mtg/l10n/app_localizations.dart';
import 'package:grimoire_mtg/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('LocaleService defaults to Polish and can switch to English', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocaleService();
    await service.init();

    expect(service.locale, const Locale('pl'));
    expect(lookupAppLocalizations(service.locale).navCollection, 'Kolekcja');

    await service.setLocale(const Locale('en'));
    expect(service.locale, const Locale('en'));
    expect(lookupAppLocalizations(service.locale).navCollection, 'Collection');
  });
}
