import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String _apiKey = "757e4c25a793b77a4fc31b2e5bf9959c";
  static const String _cacheKey = "cached_weather";
  static const String _cacheTimeKey = "cached_weather_time";

  // Durasi cache (dalam menit)
  static const int _cacheDuration = 400;

  static Map<String, dynamic>? _memoryCache;
  static DateTime? _memoryCacheTime;

  //  Ambil cuaca dari API atau cache
  static Future<Map<String, dynamic>?> fetchWeather() async {
    // 1️ Coba pakai cache di memori dulu
    if (_memoryCache != null && _memoryCacheTime != null) {
      final diff = DateTime.now().difference(_memoryCacheTime!);
      if (diff.inMinutes < _cacheDuration) {
        print(" Menggunakan cache memori");
        return _memoryCache;
      }
    }

    // 2️ Kalau cache memori sudah lama, coba ambil dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);
    final cachedTime = prefs.getString(_cacheTimeKey);

    if (cachedData != null && cachedTime != null) {
      final lastTime = DateTime.parse(cachedTime);
      final diff = DateTime.now().difference(lastTime);
      if (diff.inMinutes < _cacheDuration) {
        print("Menggunakan cache lokal (shared_preferences)");
        _memoryCache = json.decode(cachedData);
        _memoryCacheTime = lastTime;
        return _memoryCache;
      }
    }

    // 3️ Ambil lokasi
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // 4️ Fetch dari API
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=id";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      // Simpan ke memori dan lokal
      _memoryCache = data;
      _memoryCacheTime = DateTime.now();
      prefs.setString(_cacheKey, json.encode(data));
      prefs.setString(_cacheTimeKey, _memoryCacheTime!.toIso8601String());

      print(" Data cuaca baru diambil & disimpan ke cache");
      return data;
    } else {
      print(" Gagal mengambil data cuaca dari API");
      return null;
    }
  }

  //  Paksa refresh data dari API
  static Future<Map<String, dynamic>?> refreshWeather() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    _memoryCache = null;
    _memoryCacheTime = null;
    return fetchWeather();
  }
}
