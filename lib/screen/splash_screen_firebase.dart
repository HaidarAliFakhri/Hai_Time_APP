import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/page/bottom_navigator_firebase.dart';
import 'package:hai_time_app/page/login_page_firebase.dart';

class SplashScreenHaiTimeFirebase extends StatefulWidget {
  const SplashScreenHaiTimeFirebase({super.key});

  @override
  State<SplashScreenHaiTimeFirebase> createState() =>
      _SplashScreenHaiTimeFirebaseState();
}

class _SplashScreenHaiTimeFirebaseState
    extends State<SplashScreenHaiTimeFirebase>
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

    _controller.forward();

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Ambil user Firebase yang sedang login
    final user = FirebaseAuth.instance.currentUser;

    // Delay agar animasi terlihat
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (user != null) {
      // USER MASIH LOGIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BottomNavigatorFirebase()),
      );
    } else {
      // USER BELUM LOGIN
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPageFireBase()),
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
