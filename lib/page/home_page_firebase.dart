// home_page_firebase.dart
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hai_time_app/screen/profile_firebase.dart';
import 'package:hai_time_app/screen/setting_firebase.dart';
import 'package:hai_time_app/services/weather_service.dart';
import 'package:hai_time_app/view/activity_page_firebase.dart';
import 'package:hai_time_app/view/add_activities_firebase.dart';
import 'package:hai_time_app/view/prayer_schedule_page.dart';
import 'package:hai_time_app/view/weather_page.dart';
import 'package:hai_time_app/widget/sky_animation.dart';
import 'package:intl/intl.dart';

import '../model/activitymodel.dart';
import '../services/activity_service.dart';

// NOTE: db_activity.dart and model/activity.dart (sqflite) removed intentionally

enum SkyTime { subuh, dzuhur, ashar, maghrib, isya }

class HomePageFirebase extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  final VoidCallback? onGoToWeather;

  const HomePageFirebase({super.key, this.onLocaleChanged, this.onGoToWeather});

  @override
  State<HomePageFirebase> createState() => _HomePageFirebaseState();
}

//  Tambahkan TickerProviderStateMixin agar AnimationController bisa jalan
class _HomePageFirebaseState extends State<HomePageFirebase>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final KegiatanService _service = KegiatanService();
  final user = FirebaseAuth.instance.currentUser;

  String namaUser = "";
  String nextPrayerName = "";
  String nextPrayerTime = "";
  String remainingTime = "";
  bool _isAdzanPlaying = false;

  // Lokasi user (string untuk tampil cepat) dan koordinat untuk peta
  String? _userLocation;
  bool _isLoadingLocation = true;
  double? _latitude;
  double? _longitude;

  // Google Map controller untuk animate camera
  final Completer<GoogleMapController> _mapController = Completer();
  Marker? _selectedMarker;

  final Map<String, String> prayerTimes = {
    "Subuh": "04:45",
    "Dzuhur": "11:45",
    "Ashar": "14:55",
    "Maghrib": "17:47",
    "Isya": "18:59",
  };

  late AnimationController _animController;
  Timer? _prayerTimer;
  late Future<Map<String, dynamic>?> _weatherFuture;
  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });

    _weatherFuture = WeatherService.fetchWeather();
    Geolocator.requestPermission();
    _getUserLocation();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _loadNamaUser();
    _updateNextPrayer();

    // Update next prayer setiap 30 detik (sinkron dengan implementasi sebelumnya)
    _prayerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateNextPrayer(),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animController.dispose();
    _prayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // cek service & permission
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _userLocation = "GPS tidak aktif";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _userLocation = "Izin lokasi ditolak";
            _isLoadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = "Izin lokasi ditolak permanen";
          _isLoadingLocation = false;
        });
        return;
      }

      // ambil posisi akurat
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // reverse geocoding -> dapatkan alamat manusiawi
      String humanAddress = "";
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if ((p.name ?? "").isNotEmpty)
            parts.add(p.name!); // contoh: "Gedung A" atau nama tempat
          if ((p.subLocality ?? "").isNotEmpty)
            parts.add(p.subLocality!); // kelurahan / kecamatan kecil
          if ((p.locality ?? "").isNotEmpty) parts.add(p.locality!); // kota
          if ((p.administrativeArea ?? "").isNotEmpty)
            parts.add(p.administrativeArea!); // provinsi
          if ((p.country ?? "").isNotEmpty) parts.add(p.country!); // negara
          humanAddress = parts.join(', ');
        }
      } catch (e) {
        // bila geocoding gagal, fallback ke lat/lon yang lebih berguna daripada kosong
        humanAddress =
            "Lokasi terdeteksi (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})";
      }

      // set marker & store coords untuk peta (jika ada)
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _selectedMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_latitude!, _longitude!),
        );
        _userLocation = humanAddress;
        _isLoadingLocation = false;
      });

      // animate camera jika map sudah siap
      try {
        if (_mapController.isCompleted) {
          final ctrl = await _mapController.future;
          await ctrl.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(_latitude!, _longitude!), 14),
          );
        }
      } catch (_) {
        // silent
      }
    } catch (e) {
      setState(() {
        _userLocation = "Gagal mengambil lokasi";
        _isLoadingLocation = false;
        _latitude = null;
        _longitude = null;
        _selectedMarker = null;
      });
    }
  }

  Future<void> _loadNamaUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => namaUser = "User");
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Ambil username jika ada, fallback ke email
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('username')) {
      setState(() => namaUser = doc['username']);
    } else {
      setState(() => namaUser = user.email ?? "User");
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
        now.year,
        now.month,
        now.day,
        prayerDate.hour,
        prayerDate.minute,
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

    if (isPrayerNow) await _playAdzanSound();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat pagi 👋";
    if (hour >= 11 && hour < 15) return "Selamat siang 👋";
    if (hour >= 15 && hour < 18) return "Selamat sore 👋";
    return "Selamat malam 👋";
  }

  Widget _buildGreetingCard() {
    final now = DateFormat("HH:mm").format(DateTime.now());
    final timezone = DateFormat("z").format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5FA4F8), Color(0xFF0079FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Hai, $namaUser",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "$now WIB",
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  SkyTime getSkyTime() {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 6) return SkyTime.subuh;
    if (hour >= 6 && hour < 12) return SkyTime.dzuhur;
    if (hour >= 12 && hour < 15) return SkyTime.ashar;
    if (hour >= 15 && hour < 18) return SkyTime.maghrib;
    return SkyTime.isya;
  }

  List<Color> getSkyGradient(SkyTime time) {
    switch (time) {
      case SkyTime.subuh:
        return [const Color(0xFF0D1B3D), const Color(0xFF4863A0)];
      case SkyTime.dzuhur:
        return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
      case SkyTime.ashar:
        return [const Color(0xFFFFD54F), const Color(0xFFFFB300)];
      case SkyTime.maghrib:
        return [const Color(0xFFFF7043), const Color(0xFF8D6E63)];
      case SkyTime.isya:
        return [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
    }
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
                  _buildGreetingCard(),
                  const SizedBox(height: 16),
                  _buildWeatherCard(),
                  const SizedBox(height: 20),
                  _buildLocationCard(),
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
            MaterialPageRoute(
              builder: (_) => const TambahKegiatanPageFirebase(),
            ),
          );
          // StreamBuilder sudah realtime; trigger rebuild sebagai safety
          if (result == true && mounted) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //  AppBar
  Widget _buildAppBar() {
    return // Ganti SliverAppBar lama dengan ini
    SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      expandedHeight:
          120, // sesuaikan kalau CardGreeting lebih tinggi/lebih rendah
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // constraints.maxHeight akan berada antara kToolbarHeight .. expandedHeight
          final max = 120.0; // harus sama dengan expandedHeight
          final min = kToolbarHeight;
          final current = constraints.maxHeight.clamp(min, max);
          // percent = 1.0 ketika expanded (besar), 0.0 ketika collapsed (kecil)
          final percent = ((current - min) / (max - min)).clamp(0.0, 1.0);

          // threshold kapan nama kecil muncul (ketika percent turun di bawah nilai ini)
          const showCollapsedThreshold = 0.45;

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
                    // Large greeting area (visible saat expanded)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: AnimatedOpacity(
                          opacity: percent > showCollapsedThreshold ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'HaiTime',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20 + (6 * percent),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Small title that appears when collapsed
                    // positioned near top-left like a usual AppBar title
                    Positioned(
                      left: 16,
                      top: 12,
                      child: AnimatedOpacity(
                        opacity: percent <= showCollapsedThreshold ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: Transform.translate(
                          // sedikit naik turun untuk efek halus
                          offset: Offset(
                            0,
                            percent <= showCollapsedThreshold ? 0 : 6,
                          ),
                          child: Text(
                            namaUser,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Right-side icons (tetap tampil)
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
                                  builder: (_) => const ProfilePageFirebase(),
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
                                  builder: (_) => SettingPageFirebase(),
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
      future: _weatherFuture,
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
                  Text(
                    city,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
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
                      Text(
                        "$hum%",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      const Icon(Icons.air, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        "${wind.toStringAsFixed(1)} m/s",
                        style: const TextStyle(color: Colors.white),
                      ),
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
                      //
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
    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
      future: _weatherFuture,
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
          message =
              "Pertimbangkan berangkat lebih awal untuk kegiatan sore ini.";
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

  // UPDATED: _buildLocationCard now shows GoogleMap if coords available
  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: _isLoadingLocation
                    ? const Text(
                        "Mengambil lokasi...",
                        style: TextStyle(fontSize: 16),
                      )
                    : Text(
                        _userLocation ?? "Lokasi tidak tersedia",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: _getUserLocation,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_latitude != null && _longitude != null)
            SizedBox(
              height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_latitude!, _longitude!),
                    zoom: 14,
                  ),
                  markers: _selectedMarker != null ? {_selectedMarker!} : {},
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted)
                      _mapController.complete(controller);
                  },
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  //  CARD JADWAL SHOLAT
  Widget _buildPrayerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Stack(
        children: [
          // 🔵 Background animasi langit
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 280,
              width: double.infinity,
              child: SkyAnimation(
                time: getSkyTime(),
              ), // tidak diubah dari sebelumnya
            ),
          ),

          // 🔵 Overlay gelap agar teks bisa dibaca
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 270,
              width: double.infinity,
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
            ),
          ),

          // 🔵 Konten card (anti overflow)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + LIHAT SEMUA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Jadwal Sholat Hari Ini",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 🔥 FIX OVERFLOW → wrap dengan Flexible
                      Flexible(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JadwalPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat semua",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ROW LIST SHOLAT
                  const _PrayerRow(
                    icon: Icons.brightness_2_outlined,
                    name: "Subuh",
                    time: "04:45",
                  ),
                  const _PrayerRow(
                    icon: Icons.sunny,
                    name: "Dzuhur",
                    time: "11:42",
                  ),
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

                  // NEXT PRAYER
                  Text(
                    "Waktu $nextPrayerName $remainingTime",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CARD KEGIATAN
  Widget _buildKegiatanCard() {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5FA4F8), Color(0xFF0079FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Silakan login untuk melihat kegiatan.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<List<KegiatanFirebase>>(
      stream: _service.getKegiatanUser(user!.uid),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Tidak ada data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "Belum ada kegiatan.\nTambahkan kegiatanmu sekarang!",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final kegiatanList = snapshot.data!;
        final kegiatanAktif = kegiatanList
            .where((k) => k.status != "Selesai")
            .toList();

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 52, 152, 245),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kegiatan Anda",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 52, 141, 243),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${kegiatanAktif.length} Kegiatan",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Jika tidak ada kegiatan aktif
              if (kegiatanAktif.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Belum ada kegiatan.\nTekan tombol + untuk menambah.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                )
              else
                ...kegiatanAktif.map((kegiatan) {
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.blue),
                      title: Text(
                        kegiatan.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${kegiatan.lokasi}\n${kegiatan.tanggal} • ${kegiatan.waktu}",
                      ),
                      onTap: () async {
                        // buka halaman detail firebase
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KegiatanPageFirebase(kegiatan: kegiatan),
                          ),
                        );
                        // stream realtime akan otomatis update; rebuild agar UI menyesuaikan
                        if (mounted) setState(() {});
                      },
                      // long press to show actions (edit / delete)
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return SafeArea(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(ctx).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // drag handle
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // optional title / subtitle
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.event,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  kegiatan.judul,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "${kegiatan.lokasi} • ${kegiatan.tanggal} ${kegiatan.waktu}",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 6),
                                    const Divider(height: 1),

                                    // actions
                                    ListTile(
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      title: const Text('Edit'),
                                      subtitle: const Text(
                                        'Ubah detail kegiatan',
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TambahKegiatanPageFirebase(
                                                  kegiatan: kegiatan,
                                                ),
                                          ),
                                        ).then((value) {
                                          if (value == true && mounted)
                                            setState(() {});
                                        });
                                      },
                                    ),

                                    ListTile(
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.copy,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      title: const Text('Duplikat (Salin)'),
                                      subtitle: const Text(
                                        'Buat kegiatan baru berdasarkan ini',
                                      ),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        // buat copy: buka form dengan data terisi (implementasi mudah: pass kegiatan ke form but mode == new)
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TambahKegiatanPageFirebase(
                                              kegiatan: KegiatanFirebase(
                                                // pastikan model punya properti yang diperlukan; sesuaikan jika beda
                                                judul:
                                                    "${kegiatan.judul} (Copy)",
                                                lokasi: kegiatan.lokasi,
                                                tanggal: kegiatan.tanggal,
                                                waktu: kegiatan.waktu,
                                                catatan: kegiatan.catatan,
                                                pengingat: kegiatan.pengingat,
                                                status: "Belum Selesai",
                                              ),
                                            ),
                                          ),
                                        ).then((value) {
                                          if (value == true && mounted)
                                            setState(() {});
                                        });
                                      },
                                    ),

                                    ListTile(
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                      title: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      subtitle: const Text(
                                        'Hapus kegiatan ini secara permanen',
                                      ),
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        // konfirmasi sebelum menghapus
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            title: const Text(
                                              'Konfirmasi hapus',
                                            ),
                                            content: const Text(
                                              'Yakin ingin menghapus kegiatan ini? Tindakan ini tidak bisa dibatalkan.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dCtx,
                                                ).pop(false),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () => Navigator.of(
                                                  dCtx,
                                                ).pop(true),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          try {
                                            await _service.deleteKegiatan(
                                              user!.uid,
                                              kegiatan.docId ?? "",
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Kegiatan dihapus',
                                                  ),
                                                ),
                                              );
                                              setState(() {}); // refresh list
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Gagal menghapus: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),

                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }),
            ],
          ),
        );
      },
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
