import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hai_time_app/model/activitymodel.dart';
import 'package:hai_time_app/page/home_page_firebase.dart';
import 'package:hai_time_app/services/activity_service.dart';
import 'package:hai_time_app/services/notification_service.dart';
import 'package:hai_time_app/view/activity_page_firebase.dart';
import 'package:intl/intl.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';


import 'package:google_maps_flutter/google_maps_flutter.dart';



class TambahKegiatanPageFirebase extends StatefulWidget {
  final KegiatanFirebase? kegiatan;

  const TambahKegiatanPageFirebase({super.key, this.kegiatan});

  @override
  State<TambahKegiatanPageFirebase> createState() =>
      _TambahKegiatanPageFirebaseState();
}

class _TambahKegiatanPageFirebaseState
    extends State<TambahKegiatanPageFirebase> {
  double? _latitude;
  double? _longitude;

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
  const String googleApiKey = "AIzaSyDk_IqTjxDnhlwFcVf8bYfNR0qBtEGAyJw";

    if (widget.kegiatan != null) {
      _judulController.text = widget.kegiatan!.judul;
      _lokasiController.text = widget.kegiatan!.lokasi;
      _tanggalController.text = widget.kegiatan!.tanggal;
      // Pastikan waktu tersimpan sebagai HH:mm; jika data lama punya format lain, biarkan saja
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

  /// Parse waktu fleksibel: menerima "HH:mm", "H:mm", "h:mm a", "HH.mm" (mengganti '.' -> ':')
  TimeOfDay? _parseTime(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    String t = text.trim();

    // Ganti titik menjadi titik dua (banyak locale memakai 09.58)
    t = t.replaceAll('.', ':');

    // Coba beberapa pola parse secara aman
    try {
      // 1) coba jam-menit 24h (HH:mm)
      final d = DateFormat.Hm().parseLoose(t);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}

    try {
      // 2) coba format dengan am/pm (e.g., 5:30 PM)
      final d = DateFormat.jm().parseLoose(t);
      return TimeOfDay(hour: d.hour, minute: d.minute);
    } catch (_) {}

    try {
      // 3) fallback: ambil angka saja (contoh "953" -> 09:53) -- sangat permissive
      final justDigits = t.replaceAll(RegExp(r'[^0-9]'), '');
      if (justDigits.length >= 3 && justDigits.length <= 4) {
        final minutes = int.parse(justDigits.substring(justDigits.length - 2));
        final hours = int.parse(justDigits.substring(0, justDigits.length - 2));
        if (hours >= 0 && hours < 24 && minutes >= 0 && minutes < 60) {
          return TimeOfDay(hour: hours, minute: minutes);
        }
      }
    } catch (_) {}

    return null;
  }
  
  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalController.text.isNotEmpty
          ? _tryParseDate(_tanggalController.text) ?? DateTime.now()
          : DateTime.now(),
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
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      // Simpan **normalisasi** ke format 24-jam HH:mm (mis: 09:58)
      final normalized = _timeOfDayTo24HourString(picked);
      _waktuController.text = normalized;
    }
  }

  String _timeOfDayTo24HourString(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  Future<void> _pilihLokasi() async {
  Prediction? p = await PlacesAutocomplete.show(
    context: context,
    apiKey: kGoogleApiKey,
    mode: Mode.overlay,
    language: "id",
    components: [Component(Component.country, "id")],
  );

  if (p != null) {
    final places = GoogleMapsPlaces(apiKey: googleApiKey);
    final detail = await places.getDetailsByPlaceId(p.placeId!);

    final loc = detail.result.geometry!.location;

    setState(() {
      _lokasiController.text = detail.result.name;
      _latitude = loc.lat;
      _longitude = loc.lng;
    });
  }
}


  void _simpanKegiatan() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final uid = _auth.currentUser!.uid;

    final parsedTime = _parseTime(_waktuController.text);
    if (parsedTime == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Format waktu tidak valid. Gunakan 17:30."),
        ),
      );
      return;
    }

    try {
      // Build data WITHOUT notifId first
      KegiatanFirebase data = KegiatanFirebase(
      judul: _judulController.text,
      lokasi: _lokasiController.text,
      latitude: _latitude,
      longitude: _longitude,
      tanggal: _tanggalController.text,
      waktu: _timeOfDayTo24HourString(parsedTime),
      catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
      pengingat: _pengingatMenit,
      status: widget.kegiatan?.status ?? "Belum Selesai",
    );


      if (widget.kegiatan != null) {
        // EDIT: preserve docId and notifId if exists
        data = data.copyWith(
          docId: widget.kegiatan!.docId,
          notifId: widget.kegiatan!.notifId,
          createdAt: widget.kegiatan!.createdAt,
        );
        await NotifikasiService.safeCancel(data.notifId ?? 0);
        await _service.updateKegiatan(uid, data);

        // schedule using existing notifId if available, otherwise generate new and update doc
        int notifId = data.notifId ?? NotifikasiService.generateSafeNotifId();
        final notifDate = _notifDate(data);
        await NotifikasiService.safeSchedule(
          id: notifId,
          title: "Pengingat Kegiatan",
          body: "${data.judul} dimulai jam ${data.waktu}",
          date: notifDate,
        );

        // ensure notifId persisted
        if (data.notifId == null) {
          // write notifId back to document without changing other fields
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('kegiatan')
              .doc(data.docId)
              .update({'notifId': notifId});
        }
      } else {
        // ADD: create notifId first so we can store it with document atomically
        final notifId = NotifikasiService.generateSafeNotifId();
        data = data.copyWith(notifId: notifId);

        await _service.addKegiatan(uid, data);

        // schedule (safe)
        final notifDate = _notifDate(data);
        await NotifikasiService.safeSchedule(
          id: notifId,
          title: "Pengingat Kegiatan",
          body: "${data.judul} dimulai jam ${data.waktu}",
          date: notifDate,
        );
      }

      if (!mounted) return;

      // selesai: langsung kembali ke home (hapus stack)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePageFirebase()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal menyimpan: $e")));
      }
      setState(() => _isSaving = false);
    }
  }

  // ============= NOTIFIKASI =============
  Future<void> scheduleReminder(KegiatanFirebase kegiatan, String uid) async {
    final remindAt = _notifDate(kegiatan);

    if (remindAt.isBefore(DateTime.now())) return;

    final notifId =
        int.tryParse(kegiatan.docId ?? "0") ??
        DateTime.now().millisecondsSinceEpoch;

    await NotifikasiService.schedule(
      id: notifId,
      title: "Pengingat Kegiatan",
      body: "${kegiatan.judul} dimulai jam ${kegiatan.waktu}",
      date: remindAt,
    );
  }

  DateTime _notifDate(KegiatanFirebase kegiatan) {
    final date = DateFormat('dd/MM/yyyy').parse(kegiatan.tanggal);
    final timeOfDay = _parseTime(kegiatan.waktu);
    if (timeOfDay == null) {
      // Safety fallback, hindari null check operator
      throw Exception("Format waktu tidak valid saat menghitung notifikasi");
    }

    final event = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    return event.subtract(Duration(minutes: kegiatan.pengingat));
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

            GooglePlaceAutoCompleteTextField(
  textEditingController: _lokasiController,
  googleAPIKey: googleApiKey,
  inputDecoration: const InputDecoration(
    labelText: "Lokasi",
    hintText: "Cari lokasi...",
    border: OutlineInputBorder(),
  ),
  debounceTime: 800,
  countries: const ["id"],

  // ✅ Ketika user pilih lokasi
  getPlaceDetailWithLatLng: (Prediction prediction) {
    setState(() {
      _latitude = prediction.lat;
      _longitude = prediction.lng;
    });

    print("✅ Lokasi dipilih:");
    print("Place: ${prediction.description}");
    print("Lat: $_latitude");
    print("Lng: $_longitude");
  },

  // ✅ Ketika user klik salah satu hasil
  itemClick: (Prediction prediction) {
    _lokasiController.text = prediction.description!;
    _lokasiController.selection = TextSelection.fromPosition(
      TextPosition(offset: prediction.description!.length),
    );
  },
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
                final parsed = _parseTime(v);
                if (parsed == null)
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

            DropdownButtonFormField<int>(
              initialValue: _pengingatMenit,
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
      onPressed: _isSaving ? null : _simpanKegiatan,
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text("Simpan"),
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
