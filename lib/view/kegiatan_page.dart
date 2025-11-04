import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../db/db_kegiatan.dart';
import '../model/kegiatan.dart';
import 'tambah_kegiatan.dart';

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
  String mode = "driving"; // default = mobil
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
  }

  Future<void> _hitungPerjalanan() async {
    setState(() => loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak")));
          setState(() => loading = false);
          return;
        }
      }

      // Dapatkan lokasi pengguna
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Hitung jarak manual (estimasi)
      final tujuan = widget.kegiatan.lokasi;
      // Dummy estimasi waktu berdasarkan mode
      String estimasi;
      switch (mode) {
        case "walking":
          estimasi = "15-25 menit";
          break;
        case "bicycling":
          estimasi = "10-15 menit";
          break;
        case "two_wheeler":
          estimasi = "5-10 menit";
          break;
        default:
          estimasi = "5-8 menit";
      }

      setState(() {
        estimasiWaktu = estimasi;
        waktuIdeal = "Berangkat 30 menit sebelum kegiatan";
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghitung estimasi: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _bukaMaps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka Google Maps: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    // Dummy cuaca
    const cuaca = "Cerah";
    const suhu = "30°C";
    final jamCuaca = kegiatan.waktu;
    const saran =
        "Berangkat lebih awal agar tidak terjebak macet. Pastikan kondisi kendaraan prima.";

    IconData ikonCuaca = Icons.wb_sunny;
    Color warnaCuaca = Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRRect(
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
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 25),
            child: Text(
              "Detail Kegiatan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === INFO KEGIATAN ===
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kegiatan.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(kegiatan.lokasi)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Text("Tanggal: ${kegiatan.tanggal}"),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.blue,
                      ),
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
                  const Text(
                    "Informasi Perjalanan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // PILIHAN MODE TRANSPORTASI
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
                            Text(
                              "Estimasi Waktu Tempuh: ${estimasiWaktu ?? '-'}",
                            ),
                            Text(
                              "Waktu Berangkat Ideal: ${waktuIdeal ?? '-'}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),

                  const SizedBox(height: 12),

                  // Tombol buka Google Maps
                  GestureDetector(
                    onTap: _bukaMaps,
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, color: Colors.blue, size: 30),
                            Text(
                              "Lihat rute di Google Maps",
                              style: TextStyle(color: Colors.blue),
                            ),
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
              child: Row(
                children: [
                  Icon(ikonCuaca, color: warnaCuaca, size: 36),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuaca,
                        style: TextStyle(
                          color: warnaCuaca,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Suhu: $suhu • Pada $jamCuaca"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === CARD SARAN ===
            _buildCard(
              color: const Color(0xFFFFF7E5),
              borderColor: const Color(0xFFFFC107),
              child: Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(saran, style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // === CARD: CATATAN ===
            if (kegiatan.catatan != null && kegiatan.catatan!.isNotEmpty)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Catatan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(kegiatan.catatan!),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            // === TOMBOL EDIT & HAPUS ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahKegiatanPage(kegiatan: kegiatan),
                      ),
                    );
                    if (result == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.deepOrangeAccent),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Hapus",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    final konfirmasi = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Konfirmasi Hapus"),
                        content: const Text(
                          "Apakah kamu yakin ingin menghapus kegiatan ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              "Hapus",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (konfirmasi == true) {
                      await DBKegiatan().deleteKegiatan(kegiatan.id!);
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.grey,
          size: 28,
        ),
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
