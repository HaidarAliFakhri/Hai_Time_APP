import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/profile.dart';
import 'package:hai_time_app/screen/setting.dart' as setting;
import 'package:hai_time_app/view/activity_page.dart';
import 'package:hai_time_app/view/add_activities.dart';
import 'package:hai_time_app/view/prayer_schedule_page.dart';
import 'package:hai_time_app/view/weather.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_activity.dart';
import '../main.dart' as main_app;
import '../model/activity.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Kegiatan> _listKegiatan = [];
  String namaUser = "";
  String nextPrayerName = "";
  String nextPrayerTime = "";
  String remainingTime = "";
  bool _isAdzanPlaying = false;

  // Jadwal sholat sementara (bisa kamu ubah sesuai data API nanti)
  final Map<String, String> prayerTimes = {
    "Subuh": "04:45",
    "Dzuhur": "12:05",
    "Ashar": "15:20",
    "Maghrib": "18:10",
    "Isya": "19:25",
  };

  @override
  void initState() {
    super.initState();
    _loadKegiatan();
    _loadNamaUser();
    _updateNextPrayer();
    DBKegiatan().onChange.listen((_) {
    if (mounted) _loadKegiatan();
  });

    // Perbarui setiap 30 detik agar lebih responsif mendeteksi waktu adzan
    Timer.periodic(const Duration(seconds: 30), (_) => _updateNextPrayer());
  }
  

  Future<void> _loadNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => namaUser = prefs.getString('registered_name') ?? "User");
  }

  Future<void> _playAdzanSound() async {
    if (_isAdzanPlaying) return; // biar gak dobel
    try {
      _isAdzanPlaying = true;
      await _audioPlayer.play(AssetSource('audio/adzan.mp3'));
      debugPrint("🔊 Adzan diputar");
      _audioPlayer.onPlayerComplete.listen((_) {
        _isAdzanPlaying = false; // reset setelah selesai
      });
    } catch (e) {
      debugPrint("❌ Gagal memutar adzan: $e");
      _isAdzanPlaying = false;
    }
  }

  Future<void> _loadKegiatan() async {
  final data = await DBKegiatan().getKegiatanList();
  if (mounted) {
    setState(() {
      // hanya tampilkan yang belum selesai
      _listKegiatan = data.where((k) => k.status != 'Selesai').toList();
    });
  }
}


  void _updateNextPrayer() async {
    final now = DateTime.now();
    DateFormat format = DateFormat("HH:mm");
    DateTime? nextTime;
    String? nextName;

    bool isPrayerNow = false;

    for (var entry in prayerTimes.entries) {
      final prayerDate = format.parse(entry.value);
      final prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayerDate.hour,
        prayerDate.minute,
      );

      if ((now.difference(prayerDateTime).inMinutes).abs() == 0) {
        // Tepat waktu sholat
        isPrayerNow = true;
        break;
      } else if (prayerDateTime.isAfter(now)) {
        nextTime = prayerDateTime;
        nextName = entry.key;
        break;
      }
    }

    // Kalau semua sudah lewat, set ke Subuh besok
    nextTime ??= DateTime(
      now.year,
      now.month,
      now.day + 1,
      int.parse(prayerTimes["Subuh"]!.split(":")[0]),
      int.parse(prayerTimes["Subuh"]!.split(":")[1]),
    );
    nextName ??= "Subuh";

    final diff = nextTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    setState(() {
      nextPrayerName = nextName!;
      nextPrayerTime = DateFormat("HH:mm").format(nextTime!);
      remainingTime = "Dalam $hours jam $minutes menit";
    });

    // 🔊 Putar adzan jika tepat waktu sholat
    if (isPrayerNow) {
      await _playAdzanSound();
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat pagi 👋";
    if (hour >= 11 && hour < 15) return "Selamat siang 👋";
    if (hour >= 15 && hour < 18) return "Selamat sore 👋";
    return "Selamat malam 👋";
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = main_app.isDarkMode.value;
    final Color bgColor = dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F6FC);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildWeatherCard(),
                  const SizedBox(height: 20),
                  _buildPrayerCard(),
                  const SizedBox(height: 16),
                  _buildCard(
                    color: const Color(0xFFFFF6E5),
                    child: const ListTile(
                      leading: Icon(Icons.cloud, color: Colors.orange),
                      title: Text("Cuaca sore mendung"),
                      subtitle: Text(
                        "Pertimbangkan berangkat lebih awal untuk kegiatan sore ini.",
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildKegiatanCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahKegiatanPage()),
          );
          if (result == true) _loadKegiatan();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🔹 APP BAR
  Widget _buildAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 100,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final percent =
              ((constraints.maxHeight - kToolbarHeight) /
                      (100 - kToolbarHeight))
                  .clamp(0.0, 1.0);

          return ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // 👋 Greeting (hilang halus saat mulai discroll)
                    Positioned(
                      left: 5,
                      top: 12,
                      child: AnimatedOpacity(
                        opacity: percent < 0.95 ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    // 🧍 Nama user
                    AnimatedAlign(
                      alignment: Alignment(0, percent > 0.5 ? 0.5 : 0.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Text(
                        namaUser,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22 + (4 * percent),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // ⚙️ Tombol profil & setting
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const setting.SettingPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 CARD CUACA
  Widget _buildWeatherCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5FA4F8), Color(0xFF0079FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Jakarta, Indonesia",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "28°C  Cerah ☀️",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.water_drop, color: Colors.white),
              SizedBox(width: 6),
              Text("65%", style: TextStyle(color: Colors.white)),
              SizedBox(width: 20),
              Icon(Icons.air, color: Colors.white),
              SizedBox(width: 6),
              Text("15 km/h", style: TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CuacaPage()),
                );
              },
              child: const Text("Detail →"),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 CARD JADWAL SHOLAT
  Widget _buildPrayerCard() {
    return _buildCard(
      title: "Jadwal Sholat Hari Ini",
      trailing: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JadwalPage()),
          );
        },
        child: const Text("Lihat semua"),
      ),
      child: Column(
        children: [
          const _PrayerRow(
            icon: Icons.brightness_2_outlined,
            name: "Subuh",
            time: "04:45",
          ),
          const _PrayerRow(icon: Icons.sunny, name: "Dzuhur", time: "11:36"),
          const _PrayerRow(
            icon: Icons.wb_sunny_outlined,
            name: "Ashar",
            time: "14:55",
          ),
          const _PrayerRow(
            icon: Icons.nightlight_round_outlined,
            name: "Maghrib",
            time: "17:47",
          ),
          const _PrayerRow(
            icon: Icons.nightlight_round,
            name: "Isya",
            time: "18:59",
          ),
          const SizedBox(height: 10),
          Text(
            "Waktu $nextPrayerName $remainingTime",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 🔹 CARD KEGIATAN
  Widget _buildKegiatanCard() {
    return _buildCard(
      title: "Kegiatan Anda",
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("${_listKegiatan.length} Kegiatan"),
      ),
      child: Column(
        children: _listKegiatan.isEmpty
            ? [
                const Text(
                  "Belum ada kegiatan.\nTekan tombol + untuk menambah.",
                  textAlign: TextAlign.center,
                ),
              ]
            : _listKegiatan.map((kegiatan) {
                return ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(kegiatan.judul),
                  subtitle: Text(
                    "${kegiatan.lokasi}\n${kegiatan.tanggal} • ${kegiatan.waktu}",
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KegiatanPage(kegiatan: kegiatan),
                      ),
                    );
                    if (result == true) _loadKegiatan();
                  },
                );
              }).toList(),
      ),
    );
  }

  // 🔹 GENERIC CARD BUILDER
  Widget _buildCard({
    String? title,
    Widget? trailing,
    required Widget child,
    Color color = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (trailing != null) trailing,
              ],
            ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// 🔹 REUSABLE PRAYER ROW
class _PrayerRow extends StatelessWidget {
  final IconData icon;
  final String name;
  final String time;

  const _PrayerRow({
    required this.icon,
    required this.name,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
