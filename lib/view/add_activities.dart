import 'package:flutter/material.dart';
import 'package:hai_time_app/db/db_activity.dart';
import 'package:intl/intl.dart';

import '../model/activity.dart';

class TambahKegiatanPage extends StatefulWidget {
  final Kegiatan? kegiatan;
  const TambahKegiatanPage({super.key, this.kegiatan});

  @override
  State<TambahKegiatanPage> createState() => _TambahKegiatanPageState();
}

class _TambahKegiatanPageState extends State<TambahKegiatanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Jika ada kegiatan (mode edit), isi controller dari data lama
    if (widget.kegiatan != null) {
      _judulController.text = widget.kegiatan!.judul;
      _lokasiController.text = widget.kegiatan!.lokasi;
      _tanggalController.text = widget.kegiatan!.tanggal;
      _waktuController.text = widget.kegiatan!.waktu;
      _catatanController.text = widget.kegiatan!.catatan ?? '';
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _tanggalController.dispose();
    _waktuController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // helper: parse waktu string ke TimeOfDay (mencoba beberapa format umum)
  TimeOfDay? _tryParseTimeOfDay(String text) {
    if (text.isEmpty) return null;
    try {
      // Coba format jam:menit 24-jam (HH:mm)
      final d1 = DateFormat.Hm().parseLoose(text);
      return TimeOfDay(hour: d1.hour, minute: d1.minute);
    } catch (_) {}
    try {
      // Coba format 12-jam seperti "7:30 PM" atau locale-specific (jm)
      final d2 = DateFormat.jm().parseLoose(text);
      return TimeOfDay(hour: d2.hour, minute: d2.minute);
    } catch (_) {}
    // kalau gagal, return null
    return null;
  }

  // Fungsi pilih tanggal
  Future<void> _pilihTanggal() async {
    DateTime initial = DateTime.now();
    if (_tanggalController.text.isNotEmpty) {
      try {
        initial = DateFormat('dd/MM/yyyy').parseLoose(_tanggalController.text);
      } catch (_) {
        initial = DateTime.now();
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // Fungsi pilih waktu
  Future<void> _pilihWaktu() async {
    TimeOfDay initial = TimeOfDay.now();
    final parsed = _tryParseTimeOfDay(_waktuController.text);
    if (parsed != null) initial = parsed;

    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      // format waktu sesuai lokal (contoh: 07:30 PM atau 19:30 tergantung locale)
      _waktuController.text = picked.format(context);
    }
  }

  void _simpanKegiatan() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "judul": _judulController.text,
      "lokasi": _lokasiController.text,
      "tanggal": _tanggalController.text,
      "waktu": _waktuController.text,
      "catatan": _catatanController.text,
    };

    if (widget.kegiatan != null) {
      // EDIT DATA
      final updated = Kegiatan(
        id: widget.kegiatan!.id,
        judul: data['judul']!,
        lokasi: data['lokasi']!,
        tanggal: data['tanggal']!,
        waktu: data['waktu']!,
        catatan: data['catatan'],
      );
      await DBKegiatan().updateKegiatan(updated);
    } else {
      // TAMBAH BARU
      final newData = Kegiatan(
        judul: data['judul']!,
        lokasi: data['lokasi']!,
        tanggal: data['tanggal']!,
        waktu: data['waktu']!,
        catatan: data['catatan'],
      );
      await DBKegiatan().insertKegiatan(newData);
    }

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), //  tinggi AppBar
        child: AppBar(
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30), //  lengkungan kiri bawah
              bottomRight: Radius.circular(30), //  lengkungan kanan bawah
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2196F3),
                    Color(0xFF64B5F6),
                  ], // gradasi biru
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 25), // geser teks ke bawah
            child: Row(
              children: [
                Icon(
                  widget.kegiatan == null ? Icons.add : Icons.edit,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.kegiatan == null ? "Tambah Kegiatan" : "Edit Kegiatan",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Judul Kegiatan"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  hintText: "Misal: Nonton Bioskop",
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Judul tidak boleh kosong" : null,
              ),
              const SizedBox(height: 16),

              const Text("Lokasi"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  hintText: "Nama tempat atau alamat",
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              const Text("Tanggal"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Pilih tanggal",
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _pilihTanggal,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Tanggal belum dipilih" : null,
              ),
              const SizedBox(height: 16),

              const Text("Waktu"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _waktuController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Pilih waktu",
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.timer),
                    onPressed: _pilihWaktu,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Waktu belum dipilih" : null,
              ),
              const SizedBox(height: 16),

              const Text("Catatan (Opsional)"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Tambahkan catatan untuk kegiatan ini...",
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.blueAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Pengingat Otomatis\nKami akan menghitung waktu ideal berdasarkan cuaca dan jarak lokasi.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _simpanKegiatan,
                      child: const Text("Simpan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
