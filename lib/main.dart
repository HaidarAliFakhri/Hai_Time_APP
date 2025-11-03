import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:intl/date_symbol_data_local.dart';


// 🔹 Variabel global untuk kontrol tema
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// 🔹 Notifikasi instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);


  // 🔹 Inisialisasi timezone
  tz.initializeTimeZones();

  // 🔹 Inisialisasi Alarm Manager
  await AndroidAlarmManager.initialize();

  // 🔹 Inisialisasi notifikasi lokal
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HaiTime',
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

          home: const SplashScreenHaiTime(),
        );
      },
    );
  }
}
