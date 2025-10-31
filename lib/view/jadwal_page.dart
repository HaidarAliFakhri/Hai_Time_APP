import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER GRADIENT
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                60,
                24,
                28,
              ), // ✅ beri jarak manual di atas
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔸 Tombol Back (hapus kalau mau tanpa tombol back)
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
                  const Icon(
                    Ionicons.moon_outline,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Jadwal Sholat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Senin, 27 Oktober 2025\nJakarta, Indonesia",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),

                  // 🔸 KARTU SHOLAT BERIKUTNYA
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Waktu Sholat Berikutnya",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "Ashar",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Dalam 2 jam 15 menit",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Text(
                          "15:20",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 JUDUL DAFTAR SHOLAT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Semua Waktu Sholat",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Row(
                    children: const [
                      Icon(
                        Ionicons.notifications_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Pengingat",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 🔸 DAFTAR SHOLAT TANPA OVERFLOW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildPrayerCard(
                    "Subuh",
                    "04:45",
                    "10 menit sebelumnya",
                    Icons.brightness_2_outlined,
                    true,
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildPrayerCard(
                    "Dzuhur",
                    "12:05",
                    "10 menit sebelumnya",
                    Icons.wb_sunny_outlined,
                    true,
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildPrayerCard(
                    "Ashar",
                    "15:20",
                    "10 menit sebelumnya",
                    Icons.wb_twilight,
                    true,
                    false,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  _buildPrayerCard(
                    "Maghrib",
                    "18:10",
                    "10 menit sebelumnya",
                    Icons.nightlight_round_outlined,
                    true,
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildPrayerCard(
                    "Isya",
                    "19:25",
                    "10 menit sebelumnya",
                    Icons.nightlight_round,
                    true,
                    true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 KARTU ARAH KIBLAT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.navigation, color: Color(0xFF0077FF), size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Arah Kiblat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Jakarta → Mekkah   Barat Laut",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      "294°",
                      style: TextStyle(
                        color: Color(0xFF0077FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🕌 WIDGET KARTU SHOLAT
  Widget _buildPrayerCard(
    String title,
    String time,
    String subtitle,
    IconData icon,
    bool isOn,
    bool done, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: highlight ? Colors.orange : Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                if (done)
                  const Text(
                    "✔ Sudah dilaksanakan",
                    style: TextStyle(color: Colors.blue),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Switch(
                value: isOn,
                onChanged: (val) {},
                activeThumbColor: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
