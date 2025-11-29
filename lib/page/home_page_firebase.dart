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
import 'package:hai_time_app/view/add_activities_firebase.dart';
import 'package:hai_time_app/view/prayer_schedule_page.dart';
import 'package:hai_time_app/view/weather_page.dart';
import 'package:hai_time_app/widget/sky_animation.dart';
import 'package:intl/intl.dart';


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
 

// bool _isKegiatanTerlewat(KegiatanFirebase k) {
//   try {
//     final tgl = _parseTanggal(k.tanggal, waktu: k.createdAt);
//     if (tgl == null) return false;

//     // parse waktu HH:mm
//     final parts = k.waktu.split(":");
//     final jam = int.tryParse(parts[0]) ?? 0;
//     final menit = int.tryParse(parts[1]) ?? 0;

//     final dt = DateTime(tgl.year, tgl.month, tgl.day, jam, menit);

//     // gunakan helper untuk cek selesai
//     return dt.isBefore(DateTime.now()) && !_isKegiatanSelesaiModel(k);
//   } catch (_) {
//     return false;
//   }
// }



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
  // stream yang memancarkan DateTime.now() setiap detik
  final timeStream = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEEF7FF), Color(0xFFE6F0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(color: Colors.white.withOpacity(0.6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left column: greeting + name (adaptif) — beri lebih banyak flex
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // baris 1: greeting (bisa mengecil dengan ellipsis)
              Text(
                _getGreeting(),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // baris 2: halo nama user (besar) — make flexible to avoid overflow
              Text(
                "Halo, $namaUser",
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // baris kecil untuk tanggal (opsional)
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Right column: label "Time Now" di atas + jam realtime dengan animasi
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 120, // batasi lebar agar tidak menimpa kiri
            minWidth: 86,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // label kecil di atas countdown (sekarang tepat di atas)
              Text(
                "Time Now",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              // box waktu dengan animasi
              StreamBuilder<DateTime>(
                stream: timeStream,
                builder: (context, snapshot) {
                  final dt = snapshot.data ?? DateTime.now();
                  final timeText = DateFormat('HH:mm:ss').format(dt);

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    transitionBuilder: (child, animation) {
                      final offsetAnim = Tween<Offset>(
                        begin: const Offset(0, -0.06),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offsetAnim, child: child),
                      );
                    },
                    child: Container(
                      key: ValueKey<String>(timeText),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeText,
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm').format(dt),
                              style: TextStyle(
                                color: Colors.blueGrey.shade300,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
                  _buildPrayerCard(),
                  
                ],
              ),
            ),
          ),
        ],
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
                          // child: Text(
                          //   "HaiTime",
                          //   style: const TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 20,
                          //     fontWeight: FontWeight.w600,
                          //   ),
                          // ),
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
                    //test alarm kegiatan
                    // ElevatedButton(
                    //   onPressed: () async {
                    //     await NotifikasiService.safeSchedule(
                    //       id: 999998,
                    //       title: "Test Alarm",
                    //       body: "Alarm test dalam 10 detik",
                    //       date: DateTime.now().add(Duration(seconds: 15)),
                    //       soundResource: 'alarm',
                    //     );
                    //   },
                    //   child: Text("TEST ALARM"),
                    // ),
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
                          fontSize: 13,
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
          //  Background animasi langit
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

          //  Overlay gelap agar teks bisa dibaca
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 270,
              width: double.infinity,
              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.25),
            ),
          ),
          //  Konten card (anti overflow)
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

                      //  FIX OVERFLOW → wrap dengan Flexible
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


// bool _isKegiatanSelesaiModel(KegiatanFirebase k) {
//   final st = k.status.trim().toLowerCase();
//   return st == 'selesai' || st == 'done' || st == 'completed';
// }



  /// CARD KEGIATAN
//  Widget _buildKegiatanCard() {
//   if (user == null) {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color.fromARGB(255, 12, 158, 255), Color.fromARGB(255, 67, 64, 221)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: const Text(
//         "Silakan login untuk melihat kegiatan.",
//         style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
//       ),
//     );
//   }

//   return StreamBuilder<List<KegiatanFirebase>>(
//     stream: _service.getKegiatanUser(user!.uid),
//     builder: (context, snapshot) {
//       if (snapshot.connectionState == ConnectionState.waiting) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: const Color.fromARGB(255, 255, 255, 255),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: const Center(
//             child: CircularProgressIndicator(color: Color.fromARGB(255, 122, 213, 255)),
//           ),
//         );
//       }

//       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//         // reset cache when no data
//         _eventsCache = {};
//         _eventsCacheKey = "";
//         return Container(
//           padding: const EdgeInsets.all(35),
//           decoration: BoxDecoration(
//             color: const Color.fromARGB(255, 49, 128, 247),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: const Text(
//             "Belum ada kegiatan.\nTambahkan kegiatanmu sekarang!",
//             style: TextStyle(color: Colors.white),
//           ),
//         );
//       }

//       final kegiatanList = snapshot.data!;

//       // BUILD / REUSE CACHE
//       _buildEventsCache(kegiatanList);

//       // hitung kegiatan aktif untuk header-count
//       final kegiatanAktif = kegiatanList.where((k) => !_isKegiatanSelesaiModel(k)).toList();


//       return Container(
//         padding: const EdgeInsets.all(12),
//         margin: const EdgeInsets.only(bottom: 10),
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 255, 255, 255),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.blue.shade200),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   "Kegiatan Anda",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color.fromARGB(255, 0, 0, 0),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color.fromARGB(255, 52, 141, 243),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     "${kegiatanAktif.length} Kegiatan",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             // Calendar with markers
//             TableCalendar<KegiatanFirebase>(
//               firstDay: DateTime.utc(2000, 1, 1),
//               lastDay: DateTime.utc(2100, 12, 31),
//               focusedDay: _focusedDay,
//               selectedDayPredicate: (day) =>
//                   _selectedDay != null && _normalize(day) == _normalize(_selectedDay!),
//               eventLoader: (day) {
//                 return _eventsCache[_normalize(day)] ?? [];
//               },
//               calendarFormat: CalendarFormat.month,
//               onDaySelected: (selectedDay, focusedDay) {
//                 // jika klik tanggal yang sama -> jangan setState (hindari rebuild)
//                 if (_selectedDay != null && _normalize(selectedDay) == _normalize(_selectedDay!)) {
//                   // hanya fokus kalender (untuk navigasi bulan) — tapi tidak rebuild card
//                   _focusedDay = focusedDay;
//                   return;
//                 }

//                 // setState hanya ketika seleksi tanggal berubah
//                 setState(() {
//                   _selectedDay = selectedDay;
//                   _focusedDay = focusedDay;
//                 });

//                 final dayEvents = _eventsCache[_normalize(selectedDay)] ?? [];
//                 if (dayEvents.isEmpty) {
//                   return;
//                 }
//               },
//               calendarStyle: const CalendarStyle(
//                 markerDecoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                 ),
//                 markersMaxCount: 1,
//               ),
//               headerStyle: const HeaderStyle(
//                 formatButtonVisible: false,
//                 titleCentered: true,
//               ),
//               // custom marker builder: tampilkan dot kecil bila ada event
//               calendarBuilders: CalendarBuilders(
//                 markerBuilder: (context, date, events) {
//                   final dayEvents = _eventsCache[_normalize(date)];
//                   if (dayEvents == null || dayEvents.isEmpty) return const SizedBox.shrink();

//                   // return dot / badge
//                   return Positioned(
//                     bottom: 6,
//                     child: Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: const Color.fromARGB(255, 12, 0, 180), // warna dot (sesuaikan)
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             const SizedBox(height: 8),

//             // Quick preview: hanya tampilkan ringkasan bila selectedDay ada
//             if (_selectedDay != null && (_eventsCache[_normalize(_selectedDay!)]?.isNotEmpty ?? false))
//               Column(
//   crossAxisAlignment: CrossAxisAlignment.start,
//   children: [
//     const SizedBox(height: 8),
//     const Text("Ringkasan hari ini:", style: TextStyle(fontWeight: FontWeight.bold)),
//     const SizedBox(height: 6),
//     // daftar kegiatan (jika ada) untuk selected day
//     ...? _eventsCache[_normalize(_selectedDay!)]
// ?.where((k) => !_isKegiatanSelesaiModel(k))
// .map((k)  {

//       final terlewat = _isKegiatanTerlewat(k);

//       return Card(
//         color: terlewat ? const Color(0xFFFFEBEE) : Colors.white, // sedikit merah pucat kalau terlewat
//         child: ListTile(
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//           title: Text(
//             k.judul,
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               color: terlewat ? Colors.red.shade700 : Colors.black,
//             ),
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 k.waktu,
//                 style: TextStyle(
//                   color: terlewat ? Colors.red.shade700 : Colors.black54,
//                 ),
//               ),
//               if (terlewat)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Row(
//                     children: const [
//                       Icon(Icons.error_outline, size: 14, color: Colors.red),
//                       SizedBox(width: 6),
//                       Text(
//                         "Kegiatan terlewat",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//           trailing: terlewat
//               ? null
//               : const Icon(Icons.chevron_right, color: Colors.black45),
//           onTap: () async {
//   // buka halaman detail / edit. Halaman detail harus `Navigator.pop(context, 'done')`
//   // ketika user menandai selesai — lihat penjelasan setelah kode.
//   final result = await Navigator.push<String?>(
//     context,
//     MaterialPageRoute(
//       builder: (_) => KegiatanPageFirebase(kegiatan: k),
//     ),
//   );

//   // Jika halaman detail mengembalikan 'done' maka hapus item dari cache lokal (instan)
//   if (result == 'done') {
//   final key = _normalize(_selectedDay!);
//   final String removedId = (k.docId ?? '').toString();

//   setState(() {
//     _eventsCache[key]?.removeWhere((e) {
//       final ei = (e.docId ?? '').toString();
//       return ei == removedId;
//     });

//     if (_eventsCache[key]?.isEmpty ?? false) {
//       _eventsCache.remove(key);
//     }
//   });
// }

// else {
//     // bisa kosong — biarkan stream meng-handle update jika ada perubahan di server
//   }
// },

//         ),
//       );
//     }).toList(),
//   ],
// )

//             else
//               const SizedBox.shrink(),
//           ],
//         ),
//       );
//     },
//   );
// }

// caching events supaya grouping berat hanya dilakukan ketika data berubah
 // simple fingerprint

// helper untuk build events map dan detect perubahan





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
