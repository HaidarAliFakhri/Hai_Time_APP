import 'package:flutter/material.dart';
import 'package:hai_time_app/page/bottom_navigator.dart';
import 'package:hai_time_app/page/login_page.dart';
import 'package:hai_time_app/preferences/preferences_handler.dart';

class SplashScreenHaiTime extends StatefulWidget {
  const SplashScreenHaiTime({super.key});

  @override
  State<SplashScreenHaiTime> createState() => _SplashScreenHaiTimeState();
}

class _SplashScreenHaiTimeState extends State<SplashScreenHaiTime> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLogin = await PreferenceHandler.getLogin();

    // Tunggu 2 detik untuk splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLogin == true) {
      // ✅ Masuk langsung ke BottomNavigator
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigator()),
      );
    } else {
      // ⛔ Belum login → ke LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo/logo_app.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              "Welcome!!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
