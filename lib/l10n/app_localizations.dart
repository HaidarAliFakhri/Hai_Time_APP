import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Tambahkan semua delegate bawaan Flutter
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// Bahasa yang didukung aplikasi
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  // ==============================
  // Semua teks yang diterjemahkan
  // ==============================
  String get title;
  String get choose_language;
  String get language_set_to_english;
  String get language_set_to_indonesia;
  String get auto_location;
  String get time_zone;
  String get notifications;
  String get push_notification;
  String get reminder_activities;
  String get language;
  String get about;
  String get app_version;
  String get terms_conditions;
  String get privacy_policy;
  String get logout;
  String get logout_confirm;
  String get cancel;
  String get close;
  String get open_settings;
  String get location_permission_denied;
  String get location_service_disabled;
}

/// Delegate untuk memuat terjemahan
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Fungsi untuk menentukan file lokalization mana yang digunakan
AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
