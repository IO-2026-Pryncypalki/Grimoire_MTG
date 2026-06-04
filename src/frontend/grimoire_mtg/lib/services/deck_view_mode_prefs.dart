import 'package:shared_preferences/shared_preferences.dart';

import '../models/deck_view_mode.dart';

const _prefKey = 'deck_view_mode';

class DeckViewModePrefs {
  static Future<DeckViewMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return DeckViewModeX.fromName(prefs.getString(_prefKey));
  }

  static Future<void> save(DeckViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
