import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CuacaPage extends StatelessWidget {
  const CuacaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // 🔹 HEADER GRADIENT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3FA9F5), Color(0xFF0077FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Align(
                  //   alignment: Alignment.topLeft,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.arrow_back, color: Colors.white),
                  //     onPressed: () => Navigator.pop(context),
                  //     tooltip: 'Kembali',
                  //     iconSize: 26,
                  //     splashColor:
                  //         Colors.transparent, // 🔹 Hilangkan efek percikan
                  //     highlightColor:
                  //         Colors.transparent, // 🔹 Hilangkan efek tekanan
                  //   ),
                  // ),
                  const SizedBox(height: 10),
                  const Text(
                    "Jakarta, Indonesia",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  const Icon(
                    Ionicons.sunny_outline,
                    color: Colors.yellow,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "28°C",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Cerah Berawan",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Text(
                    "Terasa seperti 30°C",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 25),

                  // 🔸 INFORMASI DETAIL CUACA
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                      children: const [
                        _WeatherInfo(
                          icon: Ionicons.water_outline,
                          label: "Kelembapan",
                          value: "65%",
                        ),
                        _WeatherInfo(
                          icon: Ionicons.leaf_outline,
                          label: "Angin",
                          value: "15 km/h",
                        ),
                        _WeatherInfo(
                          icon: Ionicons.eye_outline,
                          label: "Jarak Pandang",
                          value: "10 km",
                        ),
                        _WeatherInfo(
                          icon: Ionicons.speedometer_outline,
                          label: "Tekanan",
                          value: "1013 hPa",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Prakiraan Per Jam
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prakiraan Per Jam",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔸 Scroll horizontal
                    SizedBox(
                      height: 100, // ✅ Batas tinggi biar gak overflow
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final times = [
                            "14:00",
                            "15:00",
                            "16:00",
                            "17:00",
                            "18:00",
                          ];
                          final temps = ["30°", "31°", "32°", "33°", "31°"];
                          final icons = [
                            Icons.wb_sunny_outlined,
                            Icons.cloud_outlined,
                            Icons.wb_sunny,
                            Icons.sunny,
                            Icons.cloud,
                          ];

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F9FC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    times[index],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(
                                    icons[index],
                                    color: Colors.orangeAccent,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    temps[index],
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
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 PRAKIRAAN 7 HARI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prakiraan 7 Hari",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: const [
                      _DailyForecast(
                        day: "Sen",
                        date: "27 Okt",
                        weather: "Cerah",
                        temp: "28°C",
                        icon: Ionicons.sunny_outline,
                      ),
                      _DailyForecast(
                        day: "Sel",
                        date: "28 Okt",
                        weather: "Hujan",
                        temp: "26°C",
                        icon: Ionicons.rainy_outline,
                      ),
                      _DailyForecast(
                        day: "Rab",
                        date: "29 Okt",
                        weather: "Berawan",
                        temp: "27°C",
                        icon: Ionicons.cloud_outline,
                      ),
                      _DailyForecast(
                        day: "Kam",
                        date: "30 Okt",
                        weather: "Cerah",
                        temp: "29°C",
                        icon: Ionicons.sunny_outline,
                      ),
                      _DailyForecast(
                        day: "Jum",
                        date: "31 Okt",
                        weather: "Hujan",
                        temp: "25°C",
                        icon: Ionicons.rainy_outline,
                      ),
                      _DailyForecast(
                        day: "Sab",
                        date: "1 Nov",
                        weather: "Berawan",
                        temp: "27°C",
                        icon: Ionicons.cloud_outline,
                      ),
                      _DailyForecast(
                        day: "Min",
                        date: "2 Nov",
                        weather: "Cerah",
                        temp: "30°C",
                        icon: Ionicons.sunny_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌦️ Widget untuk Info Cuaca Detail
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ☀️ Widget Prakiraan Per Jam
class _HourlyForecast extends StatelessWidget {
  final String time;
  final String temp;
  final IconData icon;
  const _HourlyForecast({
    required this.time,
    required this.temp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(height: 6),
          Text(temp, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// 🌤️ Widget Prakiraan 7 Hari
class _DailyForecast extends StatelessWidget {
  final String day;
  final String date;
  final String weather;
  final String temp;
  final IconData icon;
  const _DailyForecast({
    required this.day,
    required this.date,
    required this.weather,
    required this.temp,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(icon, color: Colors.orange, size: 28),
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
