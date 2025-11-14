import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  static final ValueNotifier<Locale> locale =
      ValueNotifier(const Locale('id'));

  static Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selectedLanguage') ?? 'id';
    locale.value = Locale(code);
  }

  static Future<void> changeLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', newLocale.languageCode);

    locale.value = newLocale;
  }
}
