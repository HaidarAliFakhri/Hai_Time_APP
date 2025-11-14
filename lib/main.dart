import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hai_time_app/l10n/app_localizations.dart';
import 'package:hai_time_app/screen/splash_screen.dart';
import 'package:hai_time_app/utils/locale_controler.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

// ------------------ THEME CONTROLLER ------------------
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// ------------------ NOTIFICATION INSTANCE ------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  tz.initializeTimeZones();
  await AndroidAlarmManager.initialize();

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Load saved locale
  await LocaleController.loadSavedLocale();

  runApp(const MyApp());
}

// =====================================================
//                     MY APP
// =====================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (_, darkMode, __) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.locale,
          builder: (_, locale, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'HaiTime',

              // Bahasa mengikuti controller
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('id'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Tema
              themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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

              home: const SplashScreenHaiTime(), // Tidak perlu onLocaleChanged
            );
          },
        );
      },
    );
  }
}
