import 'package:flutter/material.dart';
import 'package:hai_time_app/page/login_page.dart';

void main() {
  runApp(const HaiTimeApp());
}

class HaiTimeApp extends StatelessWidget {
  const HaiTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HaiTrip',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 255, 255, 255),
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      ),
      home: const LoginPage(),
    );
  }
}
