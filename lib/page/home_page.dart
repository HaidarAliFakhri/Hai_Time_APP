import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/profile.dart';
import 'package:hai_time_app/screen/setting.dart' as setting; // 👈 kasih alias
import 'package:hai_time_app/view/cuaca.dart';
import 'package:hai_time_app/screen/setting.dart';
import 'package:hai_time_app/view/jadwal_page.dart';
import 'package:hai_time_app/view/kegiatan_page.dart';
import 'package:hai_time_app/view/tambah_kegiatan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/db_kegiatan.dart';
import '../model/kegiatan.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../main.dart' as main_app; // 👈 kasih alias juga

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Kegiatan> _listKegiatan = [];
  String namaUser = "";
  String nextPrayerName = "";
  String remainingTime = "";

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
    Timer.periodic(const Duration(minutes: 1), (_) => _updateNextPrayer());
  }

  Future<void> _loadNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => namaUser = prefs.getString('registered_name') ?? "User");
  }

  Future<void> _loadKegiatan() async {
    final data = await DBKegiatan().getKegiatanList();
    if (mounted) setState(() => _listKegiatan = data);
  }

  void _updateNextPrayer() {
    final now = DateTime.now();
    DateTime? nextTime;
    String? nextName;

    for (var entry in prayerTimes.entries) {
      final prayer = DateFormat("HH:mm").parse(entry.value);
      final prayerTime = DateTime(now.year, now.month, now.day, prayer.hour, prayer.minute);
      if (prayerTime.isAfter(now)) {
        nextTime = prayerTime;
        nextName = entry.key;
        break;
      }
    }

    if (nextTime == null) {
      final subuh = prayerTimes["Subuh"]!.split(":");
      nextTime = DateTime(now.year, now.month, now.day + 1, int.parse(subuh[0]), int.parse(subuh[1]));
      nextName = "Subuh";
    }

    final diff = nextTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    setState(() {
      nextPrayerName = nextName!;
      remainingTime = "Dalam $hours jam $minutes menit";
    });
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
    final bool dark = isDarkMode.value; 
    final Color bgColor = dark ? const Color(0xFF121212) : const Color(0xFFF2F6FC);

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
                      subtitle: Text("Pertimbangkan berangkat lebih awal untuk kegiatan sore ini."),
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

  // 🔹 BAGIAN APP BAR
  Widget _buildAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 100,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final percent = ((constraints.maxHeight - kToolbarHeight) / (180 - kToolbarHeight)).clamp(0.0, 1.0);
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
                    Positioned(
                      left: 5,
                      top: 12,
                      child: Text(
                        _getGreeting(),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                    AnimatedAlign(
                      alignment: Alignment(0, percent > 0.5 ? 0.5 : 0.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Opacity(
                        opacity: percent > 0.1 ? 1 : 0,
                        child: Text(
                          namaUser,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22 + (4 * percent),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingPage()));
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
          const Text("Jakarta, Indonesia", style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          const Text("28°C  Cerah ☀️", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CuacaPage()));
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const JadwalPage()));
        },
        child: const Text("Lihat semua"),
      ),
      child: Column(
        children: [
          const _PrayerRow(icon: Icons.brightness_2_outlined, name: "Subuh", time: "04:45"),
          const _PrayerRow(icon: Icons.sunny, name: "Dzuhur", time: "12:05"),
          const _PrayerRow(icon: Icons.wb_sunny_outlined, name: "Ashar", time: "15:20"),
          const _PrayerRow(icon: Icons.nightlight_round_outlined, name: "Magrib", time: "18:10"),
          const _PrayerRow(icon: Icons.nightlight_round, name: "Isya", time: "19:25"),
          const SizedBox(height: 10),
          Text("Waktu $nextPrayerName $remainingTime",
              style: const TextStyle(fontWeight: FontWeight.w500)),
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
        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
        child: Text("${_listKegiatan.length} Kegiatan"),
      ),
      child: Column(
        children: _listKegiatan.isEmpty
            ? [
                const Text("Belum ada kegiatan.\nTekan tombol + untuk menambah.", textAlign: TextAlign.center),
              ]
            : _listKegiatan.map((kegiatan) {
                return ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(kegiatan.judul),
                  subtitle: Text("${kegiatan.lokasi}\n${kegiatan.tanggal} • ${kegiatan.waktu}"),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => KegiatanPage(kegiatan: kegiatan)),
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
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Row(children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 8),
            Text(name),
          ]),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
