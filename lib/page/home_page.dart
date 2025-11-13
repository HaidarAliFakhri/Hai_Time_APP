import 'dart:async';
import 'package:hai_time_app/services/weather_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/screen/profile.dart';
import 'package:hai_time_app/screen/setting.dart';
import 'package:hai_time_app/view/activity_page.dart';
import 'package:hai_time_app/view/add_activities.dart';
import 'package:hai_time_app/view/prayer_schedule_page.dart';
import 'package:hai_time_app/view/weather_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../db/db_activity.dart';
import '../model/activity.dart';

class HomePage extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  final VoidCallback? onGoToWeather;

  const HomePage({super.key, this.onLocaleChanged, this.onGoToWeather});

  @override
  State<HomePage> createState() => _HomePageState();
}

//  Tambahkan TickerProviderStateMixin agar AnimationController bisa jalan
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Kegiatan> _listKegiatan = [];
  String namaUser = "";
  String nextPrayerName = "";
  String nextPrayerTime = "";
  String remainingTime = "";
  bool _isAdzanPlaying = false;

  final Map<String, String> prayerTimes = {
    "Subuh": "04:45",
    "Dzuhur": "11:45",
    "Ashar": "14:55",
    "Maghrib": "17:47",
    "Isya": "18:59",
  };

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _loadKegiatan();
    _cekDanUpdateKegiatan();
    _periksaKegiatanSelesai();
    _loadNamaUser();
    _updateNextPrayer();

    DBKegiatan().onChange.listen((_) {
      if (mounted) _loadKegiatan();
    });

    Timer.periodic(const Duration(seconds: 30), (_) => _updateNextPrayer());
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _periksaKegiatanSelesai() async {
    await DBKegiatan().periksaKegiatanOtomatis();
    _loadKegiatan();
  }

  Future<void> _cekDanUpdateKegiatan() async {
    await DBKegiatan().periksaKegiatanOtomatis();
    await _loadKegiatan();
  }

  Future<void> _loadNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => namaUser = prefs.getString('registered_name') ?? "User");
  }

  Future<void> _loadKegiatan() async {
    final data = await DBKegiatan().getKegiatanList();
    if (mounted) {
      setState(() {
        _listKegiatan = data.where((k) => k.status != 'Selesai').toList();
      });
    }
  }

  Future<void> _playAdzanSound() async {
    if (_isAdzanPlaying) return;
    try {
      _isAdzanPlaying = true;
      await _audioPlayer.play(AssetSource('audio/adzan.mp3'));
      _audioPlayer.onPlayerComplete.listen((_) {
        _isAdzanPlaying = false;
      });
    } catch (e) {
      debugPrint("❌ Gagal memutar adzan: $e");
      _isAdzanPlaying = false;
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
        now.year, now.month, now.day, prayerDate.hour, prayerDate.minute,
      );

      if ((now.difference(prayerDateTime).inMinutes).abs() == 0) {
        isPrayerNow = true;
        break;
      } else if (prayerDateTime.isAfter(now)) {
        nextTime = prayerDateTime;
        nextName = entry.key;
        break;
      }
    }

    nextTime ??= DateTime(
      now.year, now.month, now.day + 1,
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

    if (isPrayerNow) await _playAdzanSound();
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
    return Scaffold(
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
                  _buildWeatherAdviceCard(), // Saran cuaca dinamis
                  const SizedBox(height: 20),
                  _buildPrayerCard(),
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

  //  AppBar
  Widget _buildAppBar() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight: 100,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final percent = ((constraints.maxHeight - kToolbarHeight) /
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
                                    builder: (_) => const ProfilePage()),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SettingPage(
                                    onLocaleChanged:
                                        widget.onLocaleChanged ?? (_) {},
                                  ),
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

  //  CARD CUACA DENGAN ANIMASI
  Widget _buildWeatherCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: WeatherService.fetchWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingWeather();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return _errorWeather();
        }

        final weather = snapshot.data!;
        final city = "${weather['name']}, ${weather['sys']['country']}";
        final temp = weather['main']['temp'].round();
        final desc = weather['weather'][0]['description'];
        final main = weather['weather'][0]['main'].toString().toLowerCase();
        final hum = weather['main']['humidity'];
        final wind = weather['wind']['speed'];

        return Stack(
          children: [
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5FA4F8), Color(0xFF0079FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Positioned.fill(
              child: AnimatedWeatherEffect(
                mainCondition: main,
                controller: _animController,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    "$temp°C  ${desc.toUpperCase()}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.white),
                      const SizedBox(width: 6),
                      Text("$hum%", style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 20),
                      const Icon(Icons.air, color: Colors.white),
                      const SizedBox(width: 6),
                      Text("${wind.toStringAsFixed(1)} m/s",
                          style: const TextStyle(color: Colors.white)),
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
    widget.onGoToWeather?.call(); //  ganti push ke callback
  },
  child: const Text("Detail →"),
),

                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _loadingWeather() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _blueBox(),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

  Widget _errorWeather() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _blueBox(),
        child: const Text(
          "Gagal memuat data cuaca ",
          style: TextStyle(color: Colors.white),
        ),
      );

  BoxDecoration _blueBox() => BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5FA4F8), Color(0xFF0079FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      );

  //  CARD SARAN CUACA DINAMIS
  Widget _buildWeatherAdviceCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: WeatherService.fetchWeather(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            color: const Color(0xFFFFF6E5),
            child: const ListTile(
              leading: Icon(Icons.cloud_queue, color: Colors.orange),
              title: Text("Mengambil data cuaca..."),
              subtitle: Text("Tunggu sebentar ya ☁️"),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildCard(
            color: const Color(0xFFFFE5E5),
            child: const ListTile(
              leading: Icon(Icons.error, color: Colors.redAccent),
              title: Text("Gagal memuat cuaca"),
              subtitle: Text("Pastikan koneksi internetmu aktif 🌐"),
            ),
          );
        }

        final data = snapshot.data!;
        final condition = data['weather'][0]['main'].toString().toLowerCase();
        IconData icon;
        String title;
        String message;
        Color bgColor;

        if (condition.contains('rain') ||
            condition.contains('drizzle') ||
            condition.contains('thunderstorm')) {
          icon = Icons.umbrella;
          title = "Cuaca sedang hujan 🌧️";
          message = "Bawa payung dan berangkat lebih awal ya.";
          bgColor = const Color(0xFFE3F2FD);
        } else if (condition.contains('cloud')) {
          icon = Icons.cloud;
          title = "Cuaca mendung ☁️";
          message = "Pertimbangkan berangkat lebih awal untuk kegiatan sore ini.";
          bgColor = const Color(0xFFFFF6E5);
        } else if (condition.contains('snow')) {
          icon = Icons.ac_unit;
          title = "Turun salju ❄️";
          message = "Kenakan pakaian hangat agar tetap nyaman.";
          bgColor = const Color(0xFFE1F5FE);
        } else {
          icon = Icons.wb_sunny;
          title = "Cuaca cerah ☀️";
          message = "Cuaca bagus! Waktu yang tepat untuk beraktivitas.";
          bgColor = const Color(0xFFE8F5E9);
        }

        return _buildCard(
          color: bgColor,
          child: ListTile(
            leading: Icon(icon, color: Colors.orange),
            title: Text(title),
            subtitle: Text(message),
          ),
        );
      },
    );
  }

  //  CARD JADWAL SHOLAT
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
              icon: Icons.brightness_2_outlined, name: "Subuh", time: "04:45"),
          const _PrayerRow(
              icon: Icons.sunny, name: "Dzuhur", time: "11:42"),
          const _PrayerRow(
              icon: Icons.wb_sunny_outlined, name: "Ashar", time: "14:55"),
          const _PrayerRow(
              icon: Icons.nightlight_round_outlined,
              name: "Maghrib",
              time: "17:47"),
          const _PrayerRow(
              icon: Icons.nightlight_round, name: "Isya", time: "18:59"),
          const SizedBox(height: 10),
          Text("Waktu $nextPrayerName $remainingTime",
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  //  CARD KEGIATAN
Widget _buildKegiatanCard() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D47A1), //  Biru gelap
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Kegiatan Anda",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_listKegiatan.length} Kegiatan",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          //  Isi Card
          if (_listKegiatan.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Belum ada kegiatan.\nTekan tombol + untuk menambah.",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: _listKegiatan.map((kegiatan) {
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.white),
                    title: Text(
                      kegiatan.judul,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "${kegiatan.lokasi}\n${kegiatan.tanggal} • ${kegiatan.waktu}",
                      style: const TextStyle(color: Colors.white70),
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
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ),
  );
}


  //  CARD GENERIC BUILDER
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
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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

//  REUSABLE PRAYER ROW
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
