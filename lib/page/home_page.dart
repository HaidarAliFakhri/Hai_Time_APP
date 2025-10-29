import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/profile.dart';
import 'package:hai_time_app/screen/setting.dart';
import 'package:hai_time_app/view/cuaca.dart';
import 'package:hai_time_app/view/jadwal_page.dart';
import 'package:hai_time_app/view/kegiatan_page.dart';
import 'package:hai_time_app/view/tambah_kegiatan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/db_kegiatan.dart';
import '../model/kegiatan.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Kegiatan> _listKegiatan = [];

  String namaUser = "";
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) {
      return "Selamat pagi 👋";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat siang 👋";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat sore 👋";
    } else {
      return "Selamat malam 👋";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadKegiatan();
    _loadNamaUser();
  }

  Future<void> _loadNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaUser = prefs.getString('registered_name') ?? "User";
    });
  }

  Future<void> _loadKegiatan() async {
    final data = await DBKegiatan().getKegiatanList();
    if (mounted) {
      setState(() {
        _listKegiatan = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkMode.value;
    final Color textColor = dark ? Colors.white : Colors.black87;
    final Color bgColor = dark
        ? const Color(0xFF121212)
        : const Color(0xFFF2F6FC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: TextStyle(color: textColor)),
            Text(
              namaUser,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black54),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card Cuaca Utama
            Container(
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Cuaca(),
                          ),
                        );
                        Navigator.pushNamed(context, '/cuaca');
                      },
                      child: const Text("Detail →"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Jadwal Sholat
            _buildCard(
              title: "Jadwal Sholat Hari Ini",
              trailing: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const JadwalPage()),
                  );
                },
                child: const Text("Lihat semua"),
              ),
              child: Column(
                children: const [
                  _PrayerRow(
                    icon: Icons.wb_twighlight,
                    name: "Subuh",
                    time: "04:45",
                  ),
                  _PrayerRow(icon: Icons.sunny, name: "Dzuhur", time: "12:05"),
                  _PrayerRow(
                    icon: Icons.wb_sunny_outlined,
                    name: "Ashar",
                    time: "15:20",
                  ),
                  SizedBox(height: 10),
                  Text("Waktu Ashar dalam 2 jam 15 menit"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cuaca sore mendung
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

            // Kegiatan Anda (DIUBAH jadi dinamis)
            _buildCard(
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
                                builder: (_) =>
                                    KegiatanPage(kegiatan: kegiatan),
                              ),
                            );
                            if (result == true) _loadKegiatan();
                          },
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),

      // Floating button: buka page tambah & simpan ke DB ketika kembali
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahKegiatanPage()),
          );

          if (result == true) {
            _loadKegiatan(); // refresh data setelah kembali
          }

          if (result != null && result is Map<String, dynamic>) {
            final kegiatan = Kegiatan(
              judul: result['judul'] ?? '',
              lokasi: result['lokasi'] ?? '',
              tanggal: result['tanggal'] ?? '',
              waktu: result['waktu'] ?? '',
              catatan: result['catatan'] ?? '',
            );
            await DBKegiatan().insertKegiatan(kegiatan);
            _loadKegiatan();
          }
        },
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.blueAccent.withOpacity(0.6),
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Jadwal"),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "Cuaca"),
        ],
      ),
    );
  }

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
