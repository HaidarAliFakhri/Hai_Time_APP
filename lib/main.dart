import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Locale Indonesia
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 🔹 Variabel global untuk kontrol tema (bisa diakses dari mana saja)
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// 🔔 Plugin notifikasi global
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ Wajib sebelum async operation
  await initializeDateFormatting('id_ID', null); // ✅ Locale Indonesia

  // ✅ Inisialisasi timezone untuk jadwal notifikasi
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  // ✅ Inisialisasi notifikasi lokal
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
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

          // 🔹 Tema terang
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F6FC),
            primarySwatch: Colors.blue,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

          // 🔹 Tema gelap
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            primarySwatch: Colors.blueGrey,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
          ),

          // 🔹 Tentukan mode aktif (berdasarkan ValueNotifier)
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,

          // 🔹 Halaman awal
          home: const SplashScreenHaiTime(),
        );
      },
    );
  }
}
