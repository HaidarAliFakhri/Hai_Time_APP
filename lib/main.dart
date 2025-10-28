import 'package:flutter/material.dart';

import 'package:hai_time_app/page/login_page.dart';



// Variabel global untuk kontrol tema
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkMode,
      builder: (context, value, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HaiTime',
          themeMode: value ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF2F6FC),
            cardColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007BFF),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4CAEFE),
            ),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}
