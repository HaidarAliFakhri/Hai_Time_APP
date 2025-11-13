import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Kelas utama localization.
/// Gunakan: AppLocalizations.of(context)!.title
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  // Mendapatkan instance localization berdasarkan context
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Delegate utama untuk localization
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Delegates yang wajib dimasukkan ke MaterialApp
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  // Bahasa yang didukung
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  // 🔹 Daftar teks yang akan diterjemahkan
  String get title;
  String get choose_language;
  String get language_set_to_english;
  String get language_set_to_indonesia;
  String get section_location_time;
  String get auto_location;
  String get timezone;
  String get section_notification;
  String get push_notification;
  String get push_notification_desc;
  String get notif_enabled;
  String get notif_disabled;
  String get section_language;
  String get app_language;
  String get section_about;
  String get app_version;
  String get terms;
  String get privacy_policy;
  String get confirm;
  String get confirm_logout;
  String get cancel;
  String get logout;
  String get logout_account;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    // Mengembalikan AppLocalizations sesuai bahasa yang dipilih
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Menentukan file localization mana yang digunakan
AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate gagal memuat locale yang tidak didukung "$locale".',
  );
}
