import 'dart:math' show sin, cos, sqrt, atan2, pi;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_time_app/db/db_activity.dart';
import 'package:hai_time_app/utils/weather_helper.dart';
import 'package:hai_time_app/view/add_activities.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/activity.dart';

class KegiatanPage extends StatefulWidget {
  final Kegiatan kegiatan;
  
const KegiatanPage({super.key, required this.kegiatan});
  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  bool loading = false;
  String? estimasiWaktu;
  String? waktuIdeal;
  String? jarakKeTujuan;
  String mode = "driving";

  Map<String, dynamic>? dataCuaca;
  String? kondisiCuaca;
  String? suhu;
  IconData ikonCuaca = Icons.cloud;
  Color warnaCuaca = Colors.blueGrey;

  final Map<String, String> modeLabel = {
    "walking": "Jalan Kaki",
    "bicycling": "Sepeda",
    "two_wheeler": "Motor",
    "driving": "Mobil",
  };

  @override
  void initState() {
    super.initState();
    _hitungPerjalanan();
    _loadCuaca();
  }

  ///  Hitung estimasi perjalanan
  Future<void> _hitungPerjalanan() async {
    setState(() => loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak")));
          setState(() => loading = false);
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
      final dest = lokasiTujuan.first;

      double jarakKm = _calculateDistance(pos.latitude, pos.longitude, dest.latitude, dest.longitude);

      double speed;
      switch (mode) {
        case "walking":
          speed = 5;
          break;
        case "bicycling":
          speed = 15;
          break;
        case "two_wheeler":
          speed = 40;
          break;
        default:
          speed = 60;
      }

      double waktuJam = jarakKm / speed;
      int waktuMenit = (waktuJam * 60).round();

      setState(() {
        estimasiWaktu = "$waktuMenit menit (±${jarakKm.toStringAsFixed(1)} km)";
        waktuIdeal = waktuMenit > 30
            ? "Berangkat 45 menit sebelum kegiatan"
            : "Berangkat 30 menit sebelum kegiatan";
        jarakKeTujuan = "${jarakKm.toStringAsFixed(1)} km";
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal menghitung estimasi: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  ///  Rumus haversine
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  ///  Buka Google Maps
  Future<void> _bukaMaps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final asal = '${pos.latitude},${pos.longitude}';
      final tujuan = Uri.encodeComponent(widget.kegiatan.lokasi);
      String travelMode = mode == "two_wheeler" ? "driving" : mode;

      final url =
          'https://www.google.com/maps/dir/?api=1&origin=$asal&destination=$tujuan&travelmode=$travelMode';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Tidak bisa membuka Google Maps";
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal membuka Google Maps: $e")));
    }
  }

  ///  Ambil data cuaca dengan cache 10 menit
  Future<void> _loadCuaca() async {
    try {
      final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
      final dest = lokasiTujuan.first;

      final cuaca = await WeatherHelper.getWeather(dest.latitude, dest.longitude);
      if (cuaca != null && mounted) {
        setState(() {
          dataCuaca = cuaca;
          kondisiCuaca = cuaca['weather'][0]['description'];
          suhu = "${cuaca['main']['temp'].round()}°C";

          switch (cuaca['weather'][0]['main'].toString().toLowerCase()) {
            case 'rain':
              ikonCuaca = Icons.water_drop;
              warnaCuaca = Colors.blueAccent;
              break;
            case 'clouds':
              ikonCuaca = Icons.cloud;
              warnaCuaca = Colors.grey;
              break;
            case 'clear':
              ikonCuaca = Icons.wb_sunny;
              warnaCuaca = Colors.orangeAccent;
              break;
            case 'thunderstorm':
              ikonCuaca = Icons.flash_on;
              warnaCuaca = Colors.deepPurpleAccent;
              break;
            default:
              ikonCuaca = Icons.wb_cloudy;
              warnaCuaca = Colors.blueGrey;
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil cuaca: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pop(context); // kembali ke halaman sebelumnya
    },
  ),
        title: const Text("Detail Kegiatan", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === INFORMASI KEGIATAN ===
            _buildCard(
              
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(kegiatan.judul,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(child: Text(kegiatan.lokasi)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text("Tanggal: ${kegiatan.tanggal}"),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text("Waktu: ${kegiatan.waktu}"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === INFORMASI PERJALANAN ===
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Informasi Perjalanan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTransportOption(Icons.directions_walk, "walking"),
                      _buildTransportOption(Icons.directions_bike, "bicycling"),
                      _buildTransportOption(Icons.motorcycle, "two_wheeler"),
                      _buildTransportOption(Icons.directions_car, "driving"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mode: ${modeLabel[mode]}"),
                            if (jarakKeTujuan != null)
                              Text("Jarak ke Tujuan: $jarakKeTujuan"),
                            Text("Estimasi: ${estimasiWaktu ?? '-'}"),
                            Text("Waktu Ideal: ${waktuIdeal ?? '-'}",
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _bukaMaps,
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, color: Colors.blue, size: 28),
                            Text("Lihat rute di Google Maps",
                                style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === CARD CUACA ===
             _buildCard(
               child: dataCuaca == null
                   ? const Center(child: CircularProgressIndicator())
                   : Row(
                       children: [
                         Icon(ikonCuaca, color: warnaCuaca, size: 36),
                         const SizedBox(width: 8),
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               kondisiCuaca ?? "Memuat...",
                               style: TextStyle(
                                 color: warnaCuaca,
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             Text("Suhu: $suhu • ${widget.kegiatan.waktu}"),
                           ],
                         ),
                       ],
                     ),
             ),

            const SizedBox(height: 8),

            // === SARAN DINAMIS ===
            _buildCard(
              color: const Color(0xFFFFF7E5),
              borderColor: const Color(0xFFFFC107),
              child: Row(
                children: [
                  Icon(
                    (kondisiCuaca ?? "").contains("rain")
                        ? Icons.umbrella
                        : Icons.lightbulb_outline,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (kondisiCuaca ?? "").contains("rain")
                          ? "Hujan terdeteksi 🌧️. Siapkan jas hujan dan berangkat lebih awal!"
                          : "Cuaca cerah ☀️. Waktu yang baik untuk beraktivitas!",
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            // === CARD: CATATAN ===
            if (kegiatan.catatan != null && kegiatan.catatan!.isNotEmpty)
              _buildCard(
                color: const Color(0xFF0D47A1), // biru lembut
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Catatan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // teks putih
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kegiatan.catatan!,
                      style: const TextStyle(
                        color: Colors.white, // teks putih agar kontras
                      ),
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 10),

            // === TOMBOL EDIT / HAPUS / SELESAI ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, elevation: 0),
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text("Edit", style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahKegiatanPage(kegiatan: kegiatan),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Colors.red),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final konfirmasi = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Konfirmasi Hapus"),
                        content: const Text("Apakah kamu yakin ingin menghapus kegiatan ini?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                          TextButton(onPressed: () => Navigator.pop(context, true),
                              child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (konfirmasi == true) {
                      await DBKegiatan().deleteKegiatan(kegiatan.id!);
                      if (mounted) Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Tandai Selesai"),
                onPressed: () async {
                  await DBKegiatan().updateKegiatan(
                    kegiatan.copyWith(status: "Selesai"),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Kegiatan ditandai sebagai selesai")),
                    );
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget kecil
  Widget _buildTransportOption(IconData icon, String value) {
    final isSelected = mode == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          mode = value;
          _hitungPerjalanan();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
        ),
        child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
    Color color = Colors.white,
    Color borderColor = Colors.transparent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
