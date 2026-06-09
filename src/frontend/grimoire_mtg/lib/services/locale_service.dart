import 'package:flutter/material.dart';

import 'locale_prefs.dart';

class LocaleService extends ChangeNotifier {
  Locale _locale = const Locale('pl');

  Locale get locale => _locale;

  Future<void> init() async {
    _locale = await LocalePrefs.load();
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    await LocalePrefs.save(locale);
    notifyListeners();
  }
}
