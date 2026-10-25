import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _localeKey = 'app_locale';
  String _locale = 'uz';
  Map<String, dynamic> _strings = {};

  String get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey) ?? 'uz';
    await _load(savedLocale, persist: false);
  }

  Future<void> setLocale(String locale) => _load(locale, persist: true);

  Future<void> _load(String locale, {required bool persist}) async {
    try {
      final raw = await rootBundle.loadString('assets/lang/$locale.json');
      _strings = jsonDecode(raw) as Map<String, dynamic>;
      _locale = locale;
      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localeKey, locale);
      }
      notifyListeners();
    } catch (e) {
      // Keep the previous language loaded.
      debugPrint('Locale load failed for $locale: $e');
      if (_strings.isEmpty) {
        _strings = {
          'nav_home': 'Home',
          'nav_movies': 'Movies',
          'nav_series': 'Series',
          'nav_live': 'Live',
          'nav_search': 'Search',
          'nav_settings': 'Settings',
        };
        notifyListeners();
      }
    }
  }

  /// Returns the translated string for [key], or the key itself if missing.
  /// `{n}` in the string is replaced by [n].
  String t(String key, {String? n}) {
    String val = _strings[key]?.toString() ?? key;
    if (n != null) val = val.replaceAll('{n}', n);
    return val;
  }
}
