import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  //  Key untuk menyimpan data
  static const String _isLoginKey = "isLogin";
  static const String _emailKey = "email";

  ///  Simpan email user
  static Future<void> setEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  ///  Ambil email user
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  ///  Simpan status login
  static Future<void> saveLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoginKey, value);
  }

  ///  Ambil status login
  static Future<bool?> getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoginKey);
  }

  ///  Hapus data login & email (saat logout)
  static Future<void> removeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoginKey);
    await prefs.remove(_emailKey);
  }
}
