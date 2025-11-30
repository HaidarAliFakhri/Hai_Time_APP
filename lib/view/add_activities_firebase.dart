// file: add_activities_firebase.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/model/activitymodel.dart';
import 'package:hai_time_app/page/bottom_navigator_firebase.dart';
import 'package:hai_time_app/services/activity_service.dart';
import 'package:hai_time_app/services/notification_service.dart';
import 'package:hai_time_app/view/custom_app_bar.dart';
import 'package:intl/intl.dart';

class TambahKegiatanPageFirebase extends StatefulWidget {
  final KegiatanFirebase? kegiatan;

  const TambahKegiatanPageFirebase({super.key, this.kegiatan});

  @override
  State<TambahKegiatanPageFirebase> createState() =>
      _TambahKegiatanPageFirebaseState();
}

class _TambahKegiatanPageFirebaseState
    extends State<TambahKegiatanPageFirebase> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  bool _isSaving = false;
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

  // ---------- parsing waktu fleksibel ----------
  TimeOfDay? _parseTime(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    var t = text.trim();
    t = t.replaceAll('.', ':'); // terima 09.30 juga

    // 1) coba HH:mm (24h)
    try {
      final d = DateFormat.Hm().parseLoose(t);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}

    // 2) coba h:mm a (AM/PM)
    try {
      final d = DateFormat.jm().parseLoose(t);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}

    // 3) fallback: angka saja "930" -> 09:30
    try {
      final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 3 && digits.length <= 4) {
        final minutes = int.parse(digits.substring(digits.length - 2));
        final hours = int.parse(digits.substring(0, digits.length - 2));
        if (hours >= 0 && hours < 24 && minutes >= 0 && minutes < 60) {
          return TimeOfDay(hour: hours, minute: minutes);
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _pilihTanggal() async {
    final initial = _tanggalController.text.isNotEmpty
        ? _tryParseDate(_tanggalController.text) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _tanggalController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  DateTime? _tryParseDate(String text) {
    try {
      return DateFormat('dd/MM/yyyy').parseLoose(text);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pilihWaktu() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      _waktuController.text = _timeOfDayTo24HourString(picked);
    }
  }

  String _timeOfDayTo24HourString(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ================= SIMPAN =================
  Future<void> _simpanKegiatan() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silakan login terlebih dahulu.")),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    final parsedTime = _parseTime(_waktuController.text);
    if (parsedTime == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Format waktu tidak valid. Contoh: 17:30"),
          ),
        );
      }
      return;
    }

    try {
      final nowIso = DateTime.now().toIso8601String();

      // Build objek awal (notifId akan di-set nanti)
      KegiatanFirebase data = KegiatanFirebase(
        docId: widget.kegiatan?.docId,
        judul: _judulController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        tanggal: _tanggalController.text.trim(),
        waktu: _timeOfDayTo24HourString(parsedTime),
        catatan: _catatanController.text.trim().isEmpty
            ? null
            : _catatanController.text.trim(),
        pengingat: _pengingatMenit,
        status: widget.kegiatan?.status ?? "Belum Selesai",
        createdAt: widget.kegiatan?.createdAt ?? nowIso,
        updatedAt: nowIso,
      );

      // Hitung tanggal notif (gabungan tanggal + waktu - pengingat)
      // Asumsi: _notifDate mengembalikan DateTime (non-nullable).
      final DateTime notifDate = _notifDate(data);

      // EDIT
      if (widget.kegiatan != null) {
        // 1) Cancel old notification jika ada (notifId nullable pada model)
        final int? oldNotifId = widget.kegiatan!.notifId;
        if (oldNotifId != null) {
          await NotifikasiService.safeCancel(oldNotifId);
          debugPrint('Cancelled old notifId=$oldNotifId (from model)');
        } else {
          // defensive fallback: mencoba membatalkan jika docId berisi angka (legacy)
          await NotifikasiService.safeCancelMaybe(widget.kegiatan!.docId);
          debugPrint(
            'Attempted fallback cancel using docId ${widget.kegiatan!.docId}',
          );
        }

        // 2) Update data umum ke Firestore (tanpa notifId)
        data = data.copyWith(docId: widget.kegiatan!.docId);
        await _service.updateKegiatan(user.uid, data);

        // 3) Buat notifId baru, schedule, dan simpan notifId ke Firestore
        final int notifId = NotifikasiService.generateSafeNotifId();
        data = data.copyWith(notifId: notifId);

        if (!notifDate.isBefore(DateTime.now())) {
          await NotifikasiService.safeSchedule(
            id: notifId,
            title: "Pengingat Kegiatan",
            body: "${data.judul} dimulai jam ${data.waktu}",
            date: notifDate,
            payload: "kegiatan_${data.docId ?? notifId}",
            soundResource: 'alarm', // pastikan file alarm tersedia
          );
          debugPrint('Scheduled new notifId=$notifId at $notifDate for edit');
        } else {
          debugPrint('NotifDate is in the past, skipping scheduling for edit');
        }

        // 4) Simpan notifId ke dokumen (update hanya field notifId)
        // Asumsi docId non-null karena editing existing doc
        await _service.updateKegiatanNotifId(user.uid, data.docId!, notifId);
      } else {
        // ADD
        // 1) Simpan doc awal ke Firestore dan dapatkan docId (addKegiatan mengembalikan String)
        final String docId = await _service.addKegiatan(user.uid, data);

        // 2) Generate notifId, update doc dengan notifId, schedule notif
        final int notifId = NotifikasiService.generateSafeNotifId();
        data = data.copyWith(docId: docId, notifId: notifId);

        if (!notifDate.isBefore(DateTime.now())) {
          await NotifikasiService.safeSchedule(
            id: notifId,
            title: "Pengingat Kegiatan",
            body: "${data.judul} dimulai jam ${data.waktu}",
            date: notifDate,
            payload: "kegiatan_$docId",
            soundResource: 'alarm',
          );
          debugPrint('Scheduled new notifId=$notifId at $notifDate for add');
        } else {
          debugPrint('NotifDate is in the past, skipping scheduling for add');
        }

        // 3) Simpan notifId ke Firestore (update field notifId saja)
        await _service.updateKegiatanNotifId(user.uid, docId, notifId);
      }

      if (!mounted) return;

      // selesai: navigasi kembali ke Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavigatorFirebase()),
        (route) => false,
      );
    } catch (e, st) {
      debugPrint('Error saving kegiatan: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
      setState(() => _isSaving = false);
    }
  }

  DateTime _notifDate(KegiatanFirebase kegiatan) {
    // parse tanggal (dd/MM/yyyy) dan waktu yang sudah dinormalisasi ke HH:mm
    final date = DateFormat('dd/MM/yyyy').parseLoose(kegiatan.tanggal);
    final tod = _parseTime(kegiatan.waktu);
    if (tod == null) {
      // safety fallback: gunakan jam 00:00
      return DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(minutes: kegiatan.pengingat));
    }

    final event = DateTime(
      date.year,
      date.month,
      date.day,
      tod.hour,
      tod.minute,
    );

    return event.subtract(Duration(minutes: kegiatan.pengingat));
  }

  // ================= UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: buildCustomAppBar(
        context,
        title: widget.kegiatan == null ? "Tambah Kegiatan" : "Edit Kegiatan",
        showBack: true,
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
              validator: (v) {
                if (v == null || v.isEmpty) return "Pilih waktu";
                if (_parseTime(v) == null)
                  return "Format waktu tidak valid. Contoh: 17:30";
                return null;
              },
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
            // DropdownButtonFormField<int>(
            //   initialValue: _pengingatMenit,
            //   decoration: const InputDecoration(labelText: "Pengingat"),
            //   onChanged: (v) => setState(() => _pengingatMenit = v ?? 0),
            //   items: const [
            //     DropdownMenuItem(value: 0, child: Text("Tidak ada")),
            //     DropdownMenuItem(value: 5, child: Text("5 menit sebelum")),
            //     DropdownMenuItem(value: 10, child: Text("10 menit sebelum")),
            //     DropdownMenuItem(value: 30, child: Text("30 menit sebelum")),
            //     DropdownMenuItem(value: 60, child: Text("1 jam sebelum")),
            //   ],
            // ),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _simpanKegiatan,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: Colors.blue.withOpacity(0.3),
          backgroundColor: _isSaving
              ? Colors.blue.shade300
              : Colors.blue, // gradient illusion via shadow
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isSaving
              ? const SizedBox(
                  key: ValueKey(1),
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.6,
                  ),
                )
              : Row(
                  key: const ValueKey(2),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Simpan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        color: Colors.white, // ← warna putih
                      ),
                    ),
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
