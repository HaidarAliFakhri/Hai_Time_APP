import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hai_time_app/l10n/app_localizations.dart';
import 'package:hai_time_app/screen/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

//  Variabel global untuk kontrol tema
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// Notifikasi instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  tz.initializeTimeZones();
  await AndroidAlarmManager.initialize();

  //  Inisialisasi notifikasi lokal
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: initSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  //  Ambil bahasa tersimpan
  final prefs = await SharedPreferences.getInstance();
  String? languageCode = prefs.getString('selectedLanguage');

  runApp(MyApp(languageCode: languageCode));
}

class MyApp extends StatefulWidget {
  final String? languageCode;
  const MyApp({super.key, this.languageCode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('id');

  @override
  void initState() {
    super.initState();
    if (widget.languageCode == 'en') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('id');
    }
  }

  void setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', locale.languageCode);
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HaiTime',
          locale: _locale,
          supportedLocales: const [Locale('en'), Locale('id')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F6FC),
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primarySwatch: Colors.blueGrey,
          ),
          home: SplashScreenHaiTime(onLocaleChanged: setLocale),
        );
      },
    );
  }
}
