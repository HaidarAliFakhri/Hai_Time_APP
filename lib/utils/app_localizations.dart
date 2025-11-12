import 'package:flutter/material.dart';

/// 🌐 Kelas utama untuk lokaliasi
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  /// Delegate wajib untuk registrasi di MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Ambil instance dari context
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Data bahasa (string yang diterjemahkan)
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'Settings',
      'choose_language': 'Choose Application Language',
      'language_set_to_english': 'Language set to English',
      'language_set_to_indonesia': 'Language set to Indonesian',
    },
    'id': {
      'title': 'Pengaturan',
      'choose_language': 'Pilih Bahasa Aplikasi',
      'language_set_to_english': 'Bahasa diatur ke Inggris',
      'language_set_to_indonesia': 'Bahasa diatur ke Indonesia',
    },
  };

  /// Fungsi terjemahan
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

/// Delegate untuk menangani pemuatan bahasa
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Tidak perlu async delay karena datanya lokal
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
