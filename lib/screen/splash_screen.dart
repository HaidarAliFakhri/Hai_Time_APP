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
    isLoginFunction();
  }

  isLoginFunction() async {
    Future.delayed(Duration(seconds: 3)).then((value) async {
      var isLogin = await PreferenceHandler.getLogin();
      print(isLogin);
      if (isLogin != null && isLogin == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => BottomNavigator()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Image.asset('assets/images/logo/logo_app.png')),
          Text(
            "Welcome!!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
