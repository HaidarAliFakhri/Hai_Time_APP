import 'package:flutter/material.dart';
import 'package:hai_time_app/db/db_activity.dart';
import 'package:intl/intl.dart';
import 'package:hai_time_app/services/notification_service.dart';

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
  int _pengingatMenit = 0;

  @override
  void initState() {
    super.initState();
    if (widget.kegiatan != null) {
      _judulController.text = widget.kegiatan!.judul;
      _lokasiController.text = widget.kegiatan!.lokasi;
      _tanggalController.text = widget.kegiatan!.tanggal;
      _waktuController.text = widget.kegiatan!.waktu;
      _catatanController.text = widget.kegiatan!.catatan ?? '';
      _pengingatMenit = widget.kegiatan!.pengingat;
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

  TimeOfDay? _parseTime(String text) {
    try {
      final d = DateFormat.jm().parseLoose(text);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}
    try {
      final d = DateFormat.Hm().parseLoose(text);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}
    return null;
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _pilihWaktu() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      _waktuController.text = picked.format(context);
    }
  }

  void _simpanKegiatan() async {
    if (!_formKey.currentState!.validate()) return;

    final data = Kegiatan(
      id: widget.kegiatan?.id,
      judul: _judulController.text,
      lokasi: _lokasiController.text,
      tanggal: _tanggalController.text,
      waktu: _waktuController.text,
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
      pengingat: _pengingatMenit,
    );

    // ============== MODE EDIT ==============
    if (widget.kegiatan != null) {
      await NotifikasiService.cancel(data.id!);
      await DBKegiatan().updateKegiatan(data);
      await scheduleReminder(data);
    } else {
      // ============== MODE TAMBAH ==============
      final id = await DBKegiatan().insertKegiatan(data);
      data.id = id;
      await scheduleReminder(data);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> scheduleReminder(Kegiatan kegiatan) async {
    final date = DateFormat('dd/MM/yyyy').parse(kegiatan.tanggal);
    final time = _parseTime(kegiatan.waktu);
    if (time == null) return;

    DateTime event = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final remindAt = event.subtract(Duration(minutes: kegiatan.pengingat));

    if (remindAt.isBefore(DateTime.now())) return;

    await NotifikasiService.schedule(
      id: kegiatan.id!,
      title: "Pengingat Kegiatan",
      body: "${kegiatan.judul} dimulai jam ${kegiatan.waktu}",
      date: remindAt,
    );
  }

  // ================= UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(120),
  child: ClipPath(
    clipper: WaveClipper(),
    child: Container(
      padding: const EdgeInsets.only(top: 5),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.kegiatan == null ? "Tambah Kegiatan" : "Edit Kegiatan",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ),
),








      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _judulController,
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                decoration: const InputDecoration(
                  labelText: "Judul Kegiatan",
                  prefixIcon: Icon(Icons.event),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _lokasiController,
                decoration: const InputDecoration(
                  labelText: "Lokasi",
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _tanggalController,
                readOnly: true,
                validator: (v) => v!.isEmpty ? "Pilih tanggal" : null,
                decoration: InputDecoration(
                  labelText: "Tanggal",
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _pilihTanggal,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _waktuController,
                readOnly: true,
                validator: (v) => v!.isEmpty ? "Pilih waktu" : null,
                decoration: InputDecoration(
                  labelText: "Waktu",
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.timer),
                    onPressed: _pilihWaktu,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                value: _pengingatMenit,
                decoration: const InputDecoration(labelText: "Pengingat"),
                onChanged: (v) => setState(() => _pengingatMenit = v ?? 0),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Tidak ada")),
                  DropdownMenuItem(value: 5, child: Text("5 menit sebelum")),
                  DropdownMenuItem(value: 10, child: Text("10 menit sebelum")),
                  DropdownMenuItem(value: 30, child: Text("30 menit sebelum")),
                  DropdownMenuItem(value: 60, child: Text("1 jam sebelum")),
                ],
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Catatan (opsional)",
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
  ),
  onPressed: _simpanKegiatan,
  child: Ink(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Container(
      alignment: Alignment.center,
      height: 50,
      child: const Text(
        "Simpan",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    ),
  ),
)






            ],
          ),
        ),
      ),
    );
  }
}
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
