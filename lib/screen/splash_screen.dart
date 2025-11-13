import 'package:flutter/material.dart';
import 'package:hai_time_app/page/home_page.dart';
import 'package:hai_time_app/page/login_page.dart';
import 'package:hai_time_app/preferences/preferences_handler.dart';

class SplashScreenHaiTime extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  const SplashScreenHaiTime({super.key, required this.onLocaleChanged});

  @override
  State<SplashScreenHaiTime> createState() => _SplashScreenHaiTimeState();
}

class _SplashScreenHaiTimeState extends State<SplashScreenHaiTime>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    //  Inisialisasi animasi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward(); // mulai animasi

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLogin = await PreferenceHandler.getLogin();

    // Tambah sedikit waktu supaya animasi terlihat
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (isLogin == true) {
      //  Masuk langsung ke BottomNavigator
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(onLocaleChanged: widget.onLocaleChanged),
        ),
      );
    } else {
      //  Belum login → ke LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(onLocaleChanged: widget.onLocaleChanged),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo/logo_app.png', height: 200),
                const SizedBox(height: 20),
                const Text(
                  "Welcome!!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const CircularProgressIndicator(color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
