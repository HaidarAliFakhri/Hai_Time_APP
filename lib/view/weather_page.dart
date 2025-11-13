import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:ionicons/ionicons.dart';

class CuacaPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CuacaPage({super.key, this.onBackToHome});

  @override
  State<CuacaPage> createState() => _CuacaPageState();
}

class _CuacaPageState extends State<CuacaPage> {
  Map<String, dynamic>? _weatherData;
  List<dynamic>? _forecastData;
  bool _loading = false;

  final String _apiKey = '757e4c25a793b77a4fc31b2e5bf9959c';

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  // 🌍 Ambil Data Cuaca + GPS
  Future<void> fetchWeather() async {
    setState(() => _loading = true);

    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen.');
      }

      // Ambil posisi sekarang
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      // URL API
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id';

      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(currentRes.body);
          _forecastData = jsonDecode(forecastRes.body)['list'];
        });
      } else {
        debugPrint('Gagal ambil data cuaca: ${currentRes.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() => _loading = false);
  }

  // 🌈 Tentukan background berdasarkan kondisi cuaca
  List<Color> _getBackgroundGradient() {
    if (_weatherData == null) {
      return [const Color(0xFF3FA9F5), const Color(0xFF0077FF)];
    }

    String main = _weatherData!['weather'][0]['main'].toString().toLowerCase();
    bool isNight = _weatherData!['weather'][0]['icon'].toString().contains('n');

    if (main.contains('rain') || main.contains('drizzle')) {
      return [const Color(0xFF4C6EF5), const Color(0xFF1E3A8A)];
    } else if (main.contains('cloud')) {
      return [const Color(0xFF93C5FD), const Color(0xFF3B82F6)];
    } else if (main.contains('clear')) {
      return isNight
          ? [const Color(0xFF0F172A), const Color(0xFF1E3A8A)]
          : [const Color(0xFF60A5FA), const Color(0xFF2563EB)];
    } else if (main.contains('storm') || main.contains('thunder')) {
      return [const Color(0xFF334155), const Color(0xFF1E293B)];
    } else {
      return [const Color(0xFF3FA9F5), const Color(0xFF0077FF)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getBackgroundGradient();

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weatherData == null
          ? Center(
              child: TextButton.icon(
                onPressed: fetchWeather,
                icon: const Icon(Icons.refresh),
                label: const Text("Gagal memuat cuaca. Coba lagi"),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // 🔹 HEADER CUACA
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 30,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    widget.onBackToHome?.call();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${_weatherData!['name']}, ${_weatherData!['sys']['country']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Icon(
                              _getWeatherIcon(),
                              color: Colors.yellowAccent,
                              size: 70,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${_weatherData!['main']['temp'].round()}°C",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _weatherData!['weather'][0]['description']
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Terasa seperti ${_weatherData!['main']['feels_like'].round()}°C",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 DETAIL INFO
                      _buildWeatherDetailCard(),

                      const SizedBox(height: 20),

                      // 🔹 PRAKIRAAN JAM
                      if (_forecastData != null) _buildHourlyForecast(),

                      const SizedBox(height: 20),

                      // 🔹 PRAKIRAAN 7 HARI
                      if (_forecastData != null) _buildDailyForecast(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 🌀 ICON CUACA BERDASARKAN KONDISI
  IconData _getWeatherIcon() {
    if (_weatherData == null) return Ionicons.partly_sunny_outline;

    String main = _weatherData!['weather'][0]['main'].toString().toLowerCase();
    if (main.contains('cloud')) return Ionicons.cloud_outline;
    if (main.contains('rain')) return Ionicons.rainy_outline;
    if (main.contains('storm')) return Ionicons.thunderstorm_outline;
    if (main.contains('snow')) return Ionicons.snow_outline;
    if (main.contains('clear')) return Ionicons.sunny_outline;
    return Ionicons.partly_sunny_outline;
  }

  // 🌡️ DETAIL INFO
  Widget _buildWeatherDetailCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _WeatherInfo(
            icon: Ionicons.water_outline,
            label: "Kelembapan",
            value: "${_weatherData!['main']['humidity']}%",
          ),
          _WeatherInfo(
            icon: Ionicons.leaf_outline,
            label: "Angin",
            value: "${_weatherData!['wind']['speed']} m/s",
          ),
          _WeatherInfo(
            icon: Ionicons.eye_outline,
            label: "Jarak Pandang",
            value:
                "${(_weatherData!['visibility'] / 1000).toStringAsFixed(1)} km",
          ),
          _WeatherInfo(
            icon: Ionicons.speedometer_outline,
            label: "Tekanan",
            value: "${_weatherData!['main']['pressure']} hPa",
          ),
        ],
      ),
    );
  }

  // ⏰ PRAKIRAAN PER JAM
  Widget _buildHourlyForecast() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Prakiraan Per Jam",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                final item = _forecastData![index];
                final time = DateTime.fromMillisecondsSinceEpoch(
                  item['dt'] * 1000,
                );
                final temp = item['main']['temp'].round().toString();
                final iconCode = item['weather'][0]['icon'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${time.hour}:00",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Image.network(
                          "https://openweathermap.org/img/wn/$iconCode@2x.png",
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$temp°C",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 📅 PRAKIRAAN 7 HARI
  Widget _buildDailyForecast() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Prakiraan 7 Hari",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          ..._forecastData!
              .where((item) => item['dt_txt'].toString().contains("12:00:00"))
              .take(7)
              .map((item) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  item['dt'] * 1000,
                );
                final temp = item['main']['temp'].round();
                final desc = item['weather'][0]['description'];
                final iconCode = item['weather'][0]['icon'];
                return _DailyForecast(
                  day: _dayName(date.weekday),
                  date: "${date.day} ${_monthName(date.month)}",
                  weather: desc,
                  temp: "$temp°C",
                  iconUrl: "https://openweathermap.org/img/wn/$iconCode.png",
                );
              }),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return months[month - 1];
  }

  String _dayName(int day) {
    const days = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
    return days[(day - 1) % 7];
  }
}

// 🌤 Widget Info Detail
class _WeatherInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// 🌦 Widget Prakiraan Harian
class _DailyForecast extends StatelessWidget {
  final String day;
  final String date;
  final String weather;
  final String temp;
  final String iconUrl;

  const _DailyForecast({
    required this.day,
    required this.date,
    required this.weather,
    required this.temp,
    required this.iconUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.network(iconUrl, width: 36, height: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$day, $date",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    weather,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          Text(
            temp,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
