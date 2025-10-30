import 'package:flutter/material.dart';

import '../db/db_kegiatan.dart';
import '../model/kegiatan.dart';
import 'tambah_kegiatan.dart';

class KegiatanPage extends StatefulWidget {
  final Kegiatan
  kegiatan; // tetap wajib (karena halaman ini memang detail 1 kegiatan)

  const KegiatanPage({super.key, required this.kegiatan});

  @override
  State<KegiatanPage> createState() => _KegiatanPageState();
}

class _KegiatanPageState extends State<KegiatanPage> {
  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    // === Data dummy untuk cuaca & perjalanan ===
    const cuaca = "Hujan"; // ubah ke Cerah / Berawan / Hujan
    const suhu = "26°C";
    final jamCuaca = kegiatan.waktu;
    const estimasiWaktu = "45 menit";
    const waktuIdeal = "15:30";
    const saran =
        "Berangkat lebih awal karena cuaca diprediksi hujan. Siapkan payung atau jas hujan.";

    // === Logika tampilan cuaca dinamis ===
    IconData ikonCuaca;
    Color warnaCuaca;

    switch (cuaca.toLowerCase()) {
      case "cerah":
        ikonCuaca = Icons.wb_sunny;
        warnaCuaca = Colors.orangeAccent;
        break;
      case "berawan":
        ikonCuaca = Icons.cloud_queue;
        warnaCuaca = Colors.grey;
        break;
      case "hujan":
        ikonCuaca = Icons.cloudy_snowing;
        warnaCuaca = Colors.blueAccent;
        break;
      default:
        ikonCuaca = Icons.wb_cloudy_outlined;
        warnaCuaca = Colors.blueGrey;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),

      // ====== APP BAR DENGAN GRADIENT + LENGKUNGAN ======
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
          centerTitle: false,
        ),
      ),

      // ====== BODY ======
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CARD: INFO KEGIATAN ===
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
                      Expanded(
                        child: Text(
                          kegiatan.lokasi,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
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

            // === CARD: CUACA ===
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Perkiraan Cuaca",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: warnaCuaca.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cuaca, style: TextStyle(color: warnaCuaca)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(ikonCuaca, color: warnaCuaca, size: 36),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suhu,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Pada $jamCuaca"),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === CARD: INFORMASI PERJALANAN ===
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Informasi Perjalanan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Buka Peta", style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Estimasi Waktu Tempuh: $estimasiWaktu"),
                  Text(
                    "Waktu Berangkat Ideal: $waktuIdeal",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                          Icon(Icons.location_on, color: Colors.blue, size: 30),
                          Text(
                            "Lihat rute lengkap",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // === CARD: SARAN ===
            _buildCard(
              color: const Color(0xFFFFF7E5),
              borderColor: const Color(0xFFFFC107),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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

            const SizedBox(height: 16),

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
                    await DBKegiatan().deleteKegiatan(kegiatan.id!);
                    if (context.mounted) Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ],
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
