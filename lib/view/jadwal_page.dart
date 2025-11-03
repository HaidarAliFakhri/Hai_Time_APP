import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

class JadwalPage extends StatefulWidget {
  const JadwalPage({super.key});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late Timer _timer;

  // 🔹 Data jadwal sholat manual
  final List<Map<String, dynamic>> jadwalSholat = [
    {
      "nama": "Subuh",
      "waktu": "04:45",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.brightness_2_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Dzuhur",
      "waktu": "12:05",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_sunny_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Ashar",
      "waktu": "15:20",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_twilight,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Maghrib",
      "waktu": "18:10",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Isya",
      "waktu": "19:25",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round,
      "aktif": true,
      "selesai": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateStatusSholat(); // Jalankan sekali saat awal
    // 🔁 Update otomatis tiap 1 menit
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateStatusSholat();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // 🔹 Fungsi: Update status otomatis berdasarkan waktu
  void _updateStatusSholat() {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    setState(() {
      for (var data in jadwalSholat) {
        final DateTime waktuSholat = format.parse(data["waktu"]);
        final DateTime waktuHariIni = DateTime(
          now.year,
          now.month,
          now.day,
          waktuSholat.hour,
          waktuSholat.minute,
        );

        // Jika waktu sekarang sudah melewati waktu sholat
        data["selesai"] = now.isAfter(waktuHariIni);
      }
    });
  }

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
            // 🔹 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
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

            // 🔹 DAFTAR WAKTU SHOLAT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(jadwalSholat.length, (index) {
                  final data = jadwalSholat[index];
                  return Column(
                    children: [
                      _buildPrayerCard(
                        data["nama"],
                        data["waktu"],
                        data["pengingat"],
                        data["ikon"],
                        data["aktif"],
                        data["selesai"],
                        highlight: index == 2,
                        onChanged: (val) {
                          setState(() {
                            data["aktif"] = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🕌 Kartu Sholat
  Widget _buildPrayerCard(
    String title,
    String time,
    String subtitle,
    IconData icon,
    bool isOn,
    bool done, {
    bool highlight = false,
    required Function(bool) onChanged,
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
                Text(
                  done ? "✔ Sudah dilaksanakan" : "Belum dilaksanakan",
                  style: TextStyle(
                    color: done ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
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
                onChanged: onChanged,
                activeThumbColor: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
