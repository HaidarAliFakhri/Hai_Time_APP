// main.dart (perbaikan minimal, fungsional identik)
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hai_time_app/l10n/app_localizations.dart';
import 'package:hai_time_app/screen/splash_screen_firebase.dart';
import 'package:hai_time_app/services/notification_service.dart';
import 'package:hai_time_app/utils/locale_controler.dart';
import 'package:intl/date_symbol_data_local.dart';
// TIMEZONE (hapus duplikat)
import 'package:timezone/data/latest.dart' as tz;

// ------------------ THEME CONTROLLER ------------------
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// ------------------ NOTIFICATION INSTANCE ------------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale dari SharedPreferences (jangan tunda terlalu lama)
  await LocaleController.loadSavedLocale();

  // firebase (init dulu agar service lain yang bergantung ke firebase aman)
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    // Log error supaya mudah dilacak; tetap lanjut bila bisa
    debugPrint('⚠️ Firebase initialization failed: $e\n$st');
  }

  // Format tanggal Indonesia
  await initializeDateFormatting('id_ID', null);

  // Timezone untuk scheduled notification
  tz.initializeTimeZones();

  // Inisialisasi notification service (plugin lokal)
  await NotifikasiService.init();

  // Alarm manager (background task)
  await AndroidAlarmManager.initialize();

  // Inisialisasi local notification (instance fallback jika diperlukan)
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  // Kalau NotifikasiService.init sudah melakukan init internal terhadap
  // flutterLocalNotificationsPlugin, memanggil initialize lagi biasanya harmless.
  // Kita tetap inisialisasi instance lokal ini untuk safety.
  await flutterLocalNotificationsPlugin.initialize(initSettings);

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
              supportedLocales: const [Locale('en'), Locale('id')],
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

              home: const SplashScreenHaiTimeFirebase(),
            );
          },
        );
      },
    );
  }
}
