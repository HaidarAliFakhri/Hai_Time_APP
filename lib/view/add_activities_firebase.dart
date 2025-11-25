import 'package:flutter/material.dart';
import 'package:hai_time_app/services/activity_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hai_time_app/services/notification_service.dart';
import 'package:hai_time_app/model/activitymodel.dart';

class TambahKegiatanPageFirebase extends StatefulWidget {
  final KegiatanFirebase? kegiatan;

  const TambahKegiatanPageFirebase({super.key, this.kegiatan});

  @override
  State<TambahKegiatanPageFirebase> createState() => _TambahKegiatanPageFirebaseState();
}

class _TambahKegiatanPageFirebaseState extends State<TambahKegiatanPageFirebase> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  int _pengingatMenit = 0;

  final _service = KegiatanService();
  final _auth = FirebaseAuth.instance;

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

  /// Try multiple time formats and return TimeOfDay or null
  TimeOfDay? _parseTime(String text) {
    if (text.trim().isEmpty) return null;

    final formats = [
      DateFormat.jm(), // e.g. 5:30 PM / 5:30 PM local format
      DateFormat.Hm(), // e.g. 17:30
    ];

    for (var f in formats) {
      try {
        final d = f.parseLoose(text);
        return TimeOfDay(hour: d.hour, minute: d.minute);
      } catch (_) {
        // continue trying other formats
      }
    }
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

  /// Build DateTime for notification; returns null if parsing fails
  DateTime? _notifDateSafe(KegiatanFirebase kegiatan) {
    try {
      if (kegiatan.tanggal.trim().isEmpty || kegiatan.waktu.trim().isEmpty) {
        return null;
      }

      final date = DateFormat('dd/MM/yyyy').parseLoose(kegiatan.tanggal);
      final timeOfDay = _parseTime(kegiatan.waktu);

      if (timeOfDay == null) return null;

      final event = DateTime(
        date.year,
        date.month,
        date.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      return event.subtract(Duration(minutes: kegiatan.pengingat));
    } catch (e) {
      // parsing error
      return null;
    }
  }

  /// Schedule notification if remindAt is valid and in the future
  Future<void> _maybeScheduleNotification({
    required int notifId,
    required KegiatanFirebase kegiatan,
  }) async {
    final remindAt = _notifDateSafe(kegiatan);
    if (remindAt == null) {
      // nothing to schedule (invalid date/time)
      return;
    }
    if (remindAt.isBefore(DateTime.now())) {
      // past time -> do not schedule
      return;
    }
    await NotifikasiService.schedule(
      id: notifId,
      title: "Pengingat Kegiatan",
      body: "${kegiatan.judul} dimulai jam ${kegiatan.waktu}",
      date: remindAt,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _simpanKegiatan() async {
    if (!_formKey.currentState!.validate()) return;

    // VALIDASI PARSING tanggal & waktu terlebih dahulu supaya tidak crash
    final tanggalText = _tanggalController.text.trim();
    final waktuText = _waktuController.text.trim();

    if (tanggalText.isEmpty || waktuText.isEmpty) {
      _showError("Tanggal dan waktu harus diisi.");
      return;
    }

    // cek parse tanggal
    DateTime? parsedDate;
    try {
      parsedDate = DateFormat('dd/MM/yyyy').parseLoose(tanggalText);
    } catch (e) {
      _showError("Format tanggal tidak valid. Gunakan dd/MM/yyyy.");
      return;
    }

    // cek parse waktu
    final parsedTime = _parseTime(waktuText);
    if (parsedTime == null) {
      _showError("Format waktu tidak valid. Contoh: 17:30 atau 5:30 PM.");
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _showError("Silakan login terlebih dahulu.");
      return;
    }

    // BUILD DATA SESUAI MODEL
    final statusFix = widget.kegiatan?.status ?? "Belum Selesai";

    KegiatanFirebase data = KegiatanFirebase(
      docId: widget.kegiatan?.docId,
      judul: _judulController.text,
      lokasi: _lokasiController.text,
      tanggal: tanggalText,
      waktu: waktuText,
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
      pengingat: _pengingatMenit,
      status: statusFix,
    );

    // MODE EDIT
    if (widget.kegiatan != null) {
      // cancel existing notification if docId was used as id
      final oldNotifId = int.tryParse(widget.kegiatan!.docId ?? "0") ?? 0;
      if (oldNotifId != 0) {
        await NotifikasiService.cancel(oldNotifId);
      }

      // update in firestore
      await _service.updateKegiatan(uid, data);

      // reschedule using same notif id if docId is numeric, otherwise skip
      final notifId = int.tryParse(data.docId ?? "") ?? 0;
      if (notifId != 0) {
        await _maybeScheduleNotification(notifId: notifId, kegiatan: data);
      } else {
        // fallback: schedule using timestamp id (but do not cancel previous because old id used)
        final fallbackId = DateTime.now().millisecondsSinceEpoch;
        await _maybeScheduleNotification(notifId: fallbackId, kegiatan: data);
      }
    } 
    // MODE TAMBAH
    else {
      // Add to Firestore — service will generate docId
      await _service.addKegiatan(uid, data);

      // We don't know the docId returned by Firestore immediately.
      // Use timestamp-based notif id to schedule reliably.
      final newNotifId = DateTime.now().millisecondsSinceEpoch;
      await _maybeScheduleNotification(notifId: newNotifId, kegiatan: data);
    }

    if (mounted) Navigator.pop(context, true);
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

      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
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
            _tombolSimpan(),
          ],
        ),
      ),
    );
  }

  Widget _tombolSimpan() {
    return ElevatedButton(
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
