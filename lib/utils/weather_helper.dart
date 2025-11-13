import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherHelper {
  static const _cacheKey = 'cached_weather';
  static const _cacheDuration = Duration(minutes: 10);
  static const _apiKey = '757e4c25a793b77a4fc31b2e5bf9959c';

  static Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt('${_cacheKey}_time');

    if (cachedData != null && cachedTime != null) {
      final age = now.difference(DateTime.fromMillisecondsSinceEpoch(cachedTime));
      if (age < _cacheDuration) {
        return jsonDecode(cachedData);
      }
    }

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      prefs.setString(_cacheKey, response.body);
      prefs.setInt('${_cacheKey}_time', now.millisecondsSinceEpoch);
      return jsonDecode(response.body);
    }
    return null;
  }
}
