import 'dart:convert';
import 'dart:math';
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

class _CuacaPageState extends State<CuacaPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  List<dynamic>? _forecastData;
  bool _loading = false;

  final String _apiKey = '757e4c25a793b77a4fc31b2e5bf9959c';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
    fetchWeather();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=id';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=id';

      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(currentRes.body);
          _forecastData = jsonDecode(forecastRes.body)['list'];
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _loading = false);
  }

  List<Color> _getBackgroundGradient() {
    if (_weatherData == null) {
      return [Colors.blueAccent, Colors.indigo];
    }

    String main = _weatherData!['weather'][0]['main'].toLowerCase();

    if (main.contains('rain')) {
      return [Colors.indigo.shade600, Colors.indigo.shade900];
    } else if (main.contains('cloud')) {
      return [Colors.blue.shade300, Colors.blue.shade700];
    } else if (main.contains('clear')) {
      return [Colors.lightBlueAccent, Colors.blue.shade700];
    } else if (main.contains('snow')) {
      return [Colors.grey.shade200, Colors.grey.shade400];
    } else if (main.contains('thunder')) {
      return [Colors.grey.shade800, Colors.black];
    } else {
      return [Colors.lightBlueAccent, Colors.blueAccent];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getBackgroundGradient();

    return Scaffold(
      body: Stack(
        children: [
          //  Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          //  Animasi Cuaca
          if (_weatherData != null)
            AnimatedWeatherEffect(
              mainCondition:
                  _weatherData!['weather'][0]['main'].toString().toLowerCase(),
              controller: _animController,
            ),

          //  Konten Cuaca
          _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _weatherData == null
                  ? Center(
                      child: TextButton.icon(
                        onPressed: fetchWeather,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          "Gagal memuat cuaca. Coba lagi",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : _buildWeatherContent(),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                widget.onBackToHome?.call(); // kembali ke tab Home
              },
            ),
            ),
            Text(
              "${_weatherData!['name']}, ${_weatherData!['sys']['country']}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Icon(_getWeatherIcon(), color: Colors.yellowAccent, size: 70),
            Text(
              "${_weatherData!['main']['temp'].round()}°C",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40),
            ),
            Text(
              _weatherData!['weather'][0]['description']
                  .toString()
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              "Terasa seperti ${_weatherData!['main']['feels_like'].round()}°C",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),

            //  Detail info
            _buildWeatherDetailCard(),
            const SizedBox(height: 20),

            //  Prakiraan 12 Jam ke Depan
            if (_forecastData != null) _buildHourlyForecast(),

            //  Prakiraan 5 Hari ke Depan
            if (_forecastData != null) _buildDailyForecast(),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon() {
    String main = _weatherData!['weather'][0]['main'].toLowerCase();
    if (main.contains('cloud')) return Ionicons.cloud_outline;
    if (main.contains('rain')) return Ionicons.rainy_outline;
    if (main.contains('thunder')) return Ionicons.thunderstorm_outline;
    if (main.contains('snow')) return Ionicons.snow_outline;
    if (main.contains('clear')) return Ionicons.sunny_outline;
    return Ionicons.partly_sunny_outline;
  }

  Widget _buildWeatherDetailCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
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

  Widget _buildHourlyForecast() {
    final next12Hours = _forecastData!.take(12).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Prakiraan 12 Jam Kedepan",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: next12Hours.length,
              itemBuilder: (context, i) {
                final item = next12Hours[i];
                final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
                final icon = item['weather'][0]['icon'];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 75,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${dt.hour}:00",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Image.network(
                        "https://openweathermap.org/img/wn/$icon.png",
                        width: 40,
                      ),
                      Text("${item['main']['temp'].round()}°C"),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    // Kelompokkan per tanggal (ambil jam 12:00)
    final days = _forecastData!
        .where((item) => item['dt_txt'].toString().contains("12:00:00"))
        .take(10)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Prakiraan 5 Hari Kedepan",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Column(
            children: days.map((item) {
              final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
              final desc = item['weather'][0]['description'];
              final icon = item['weather'][0]['icon'];
              final temp = item['main']['temp'].round();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.network("https://openweathermap.org/img/wn/$icon.png",
                            width: 40),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${_dayName(dt.weekday)}, ${dt.day} ${_monthName(dt.month)}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(desc,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        )
                      ],
                    ),
                    Text("$temp°C",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  String _dayName(int day) {
    const list = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
    return list[(day - 1) % 7];
  }

  String _monthName(int month) {
    const list = [
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
      "Des"
    ];
    return list[month - 1];
  }
}

// ─────────────────────────────
///  Widget Info Cuaca
class _WeatherInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherInfo(
      {required this.icon, required this.label, required this.value});

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
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────
///  Animasi Cuaca Otomatis
class AnimatedWeatherEffect extends StatelessWidget {
  final String mainCondition;
  final AnimationController controller;
  const AnimatedWeatherEffect(
      {super.key, required this.mainCondition, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (mainCondition.contains('rain')) {
      return RainAnimation(controller: controller);
    } else if (mainCondition.contains('cloud')) {
      return CloudAnimation(controller: controller);
    } else if (mainCondition.contains('thunder')) {
      return ThunderAnimation(controller: controller);
    } else if (mainCondition.contains('snow')) {
      return SnowAnimation(controller: controller);
    } else if (mainCondition.contains('clear')) {
      return SunAnimation(controller: controller);
    }
    return const SizedBox.shrink();
  }
}

//  Hujan
class RainAnimation extends StatelessWidget {
  final AnimationController controller;
  const RainAnimation({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final random = Random();
        return CustomPaint(
          painter: _RainPainter(random, controller.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _RainPainter extends CustomPainter {
  final Random random;
  final double progress;
  _RainPainter(this.random, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2;
    for (int i = 0; i < 90; i++) {
      double x = random.nextDouble() * size.width;
      double y =
          (random.nextDouble() * size.height + progress * size.height) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
//  Awan
class CloudAnimation extends StatelessWidget {
  final AnimationController controller;
  const CloudAnimation({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Positioned(
          top: 100,
          left: (controller.value * MediaQuery.of(context).size.width * 1.5) - 200,
          child: Icon(Ionicons.cloud, color: Colors.white60, size: 160),
        );
      },
    );
  }
}

//  Petir
class ThunderAnimation extends StatelessWidget {
  final AnimationController controller;
  const ThunderAnimation({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        bool flash = controller.value > 0.9;
        return Container(
          color: flash ? Colors.white.withOpacity(0.5) : Colors.transparent,
        );
      },
    );
  }
}

// Salju
class SnowAnimation extends StatelessWidget {
  final AnimationController controller;
  const SnowAnimation({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final random = Random();
        return CustomPaint(
          painter: _SnowPainter(random, controller.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _SnowPainter extends CustomPainter {
  final Random random;
  final double progress;
  _SnowPainter(this.random, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.9);
    for (int i = 0; i < 50; i++) {
      double x = random.nextDouble() * size.width;
      double y =
          (random.nextDouble() * size.height + progress * size.height) % size.height;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) => true;
}

//  Cerah
class SunAnimation extends StatelessWidget {
  final AnimationController controller;
  const SunAnimation({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: controller,
        child: const Icon(Ionicons.sunny, color: Colors.yellowAccent, size: 150),
      ),
    );
  }
}
