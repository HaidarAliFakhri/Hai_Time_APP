// lib/pages/kegiatan_page_firebase.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hai_time_app/model/activitymodel.dart';
import 'package:hai_time_app/services/activity_service.dart';
import 'package:hai_time_app/services/notification_service.dart' as notif_service;
import 'package:hai_time_app/services/weather_service.dart';
import 'package:hai_time_app/view/add_activities_firebase.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hai_time_app/page/bottom_navigator_firebase.dart';

const String kGoogleApiKey = 'AIzaSyDk_IqTjxDnhlwFcVf8bYfNR0qBtEGAyJw';

class KegiatanPageFirebase extends StatefulWidget {
  final KegiatanFirebase kegiatan;

  const KegiatanPageFirebase({super.key, required this.kegiatan});

  @override
  State<KegiatanPageFirebase> createState() => _KegiatanPageFirebaseState();
}

class _KegiatanPageFirebaseState extends State<KegiatanPageFirebase> {
  final KegiatanService _service = KegiatanService();

  bool _isMarkingDone = false;
  bool _isDeleting = false;
  bool loading = false;

  // Display fields (will be set only when user inputs)
  String? jarakKeTujuan; // tampilkan jika user masukkan
  int? estimasiMinutes; // hasil perhitungan dari input user
  String? estimasiWaktu; // human friendly dari estimasiMinutes

  String mode = "driving";

  // Weather
  Map<String, dynamic>? dataCuaca;
  String? kondisiCuaca;
  String? suhu;
  IconData ikonCuaca = Icons.cloud;
  Color warnaCuaca = Colors.blueGrey;

  // Maps
  GoogleMapController? _mapController;
  CameraPosition? _initialCamera;
  LatLng? _origin;
  LatLng? _dest;
  final Set<Marker> _markers = {};
  final Map<PolylineId, Polyline> _polylines = {};

  // Countdown
  Timer? _countdownTimer;

  // Input controller
  final TextEditingController _distanceController = TextEditingController();
  bool _isApplyingDistance = false;

  final Map<String, String> modeLabel = {
    "walking": "Jalan Kaki",
    "bicycling": "Sepeda",
    "two_wheeler": "Motor",
    "driving": "Mobil",
  };

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _countdownTimer?.cancel();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    await _loadWeather();
    await _prepareMapAndRoute();

    // jika kegiatan sudah punya jarakManual/saran, tampilkan segera
    if (widget.kegiatan.jarakManualKm != null) {
      _distanceController.text = widget.kegiatan.jarakManualKm!.toStringAsFixed(1);
      setState(() {
        jarakKeTujuan = "${widget.kegiatan.jarakManualKm!.toStringAsFixed(1)} km (tersimpan)";
        estimasiWaktu = widget.kegiatan.saranBerangkat ?? estimasiWaktu;
      });
    } else if (widget.kegiatan.saranBerangkat != null) {
      // kalau hanya saran yang tersimpan (misal tersimpan manual sebelumnya), tampilkan
      setState(() {
        estimasiWaktu = widget.kegiatan.saranBerangkat;
      });
    }

    _startCountdown();
    _ensureReminderScheduled();
  }

  Future<void> _loadWeather() async {
    try {
      final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
      final dest = lokasiTujuan.first;
      final cuaca = await WeatherService.getWeather(dest.latitude, dest.longitude);

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

  /// Pastikan kedua titik (origin/dest) dan/atau polyPoints terlihat.
  Future<void> _fitMapToBounds({List<LatLng>? polyPoints, double padding = 60}) async {
    if (_mapController == null) return;

    try {
      // kumpulkan semua titik yang relevan
      final List<LatLng> points = [];

      if (polyPoints != null && polyPoints.isNotEmpty) {
        points.addAll(polyPoints);
      }

      if (_origin != null) points.add(_origin!);
      if (_dest != null) points.add(_dest!);

      if (points.isEmpty) return;

      // hitung min/max lat/lng
      final latitudes = points.map((p) => p.latitude).toList();
      final longitudes = points.map((p) => p.longitude).toList();

      final southWest = LatLng(latitudes.reduce(min), longitudes.reduce(min));
      final northEast = LatLng(latitudes.reduce(max), longitudes.reduce(max));

      final bounds = LatLngBounds(southwest: southWest, northeast: northEast);

      // animate camera ke bounds (gunakan try/catch karena animateCamera bisa throw)
      await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, padding));
    } catch (e) {
      debugPrint("Gagal fit bounds: $e");
      // fallback: jika gagal, zoom ke center origin/dest
      try {
        if (_origin != null && _dest != null) {
          final centerLat = (_origin!.latitude + _dest!.latitude) / 2;
          final centerLng = (_origin!.longitude + _dest!.longitude) / 2;
          await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 12));
        }
      } catch (_) {}
    }
  }

  /// Prepare map and draw polyline between origin (user) and destination.
  /// IMPORTANT: we DO NOT compute/display distance or automatic estimations here.
  Future<void> _prepareMapAndRoute() async {
    setState(() => loading = true);

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
      final dest = lokasiTujuan.first;

      _origin = LatLng(pos.latitude, pos.longitude);
      _dest = LatLng(dest.latitude, dest.longitude);

      final centerLat = (_origin!.latitude + _dest!.latitude) / 2;
      final centerLng = (_origin!.longitude + _dest!.longitude) / 2;
      _initialCamera = CameraPosition(target: LatLng(centerLat, centerLng), zoom: 12);

      _markers.clear();
      _markers.add(Marker(markerId: const MarkerId('origin'), position: _origin!, infoWindow: const InfoWindow(title: 'Lokasimu')));
      _markers.add(Marker(markerId: const MarkerId('dest'), position: _dest!, infoWindow: InfoWindow(title: 'Tujuan')));

      // Try directions only to get polyline points for display.
      Map<String, dynamic>? directions;
      try {
        directions = await _fetchDirections(_origin!.latitude, _origin!.longitude, _dest!.latitude, _dest!.longitude, travelMode: mode == "two_wheeler" ? "driving" : mode);
      } catch (e) {
        directions = null;
      }

      List<LatLng> polyPoints = [];

      if (directions != null) {
        try {
          final route = directions['routes'][0];
          final encodedPolyline = route['overview_polyline']?['points'];
          if (encodedPolyline != null) {
            final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);
            polyPoints = decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
          }
        } catch (e) {
          debugPrint('Error parsing directions polyline: $e');
          polyPoints = [];
        }
      }

      setState(() {
        _polylines.clear();
        if (polyPoints.isNotEmpty) {
          final id = const PolylineId('route_poly');
          _polylines[id] = Polyline(polylineId: id, points: polyPoints, color: Colors.blue, width: 5);
        }
      });

      // Fit camera to polyline or origin/dest via helper
      await _fitMapToBounds(polyPoints: polyPoints);
    } catch (e) {
      debugPrint("Error prepareMapAndRoute: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat rute")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchDirections(double originLat, double originLng, double destLat, double destLng, {String travelMode = "driving"}) async {
    try {
      final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&mode=$travelMode'
          '&key=$kGoogleApiKey');
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] != 'OK') return null;
      return data;
    } catch (e) {
      debugPrint('Fetch directions error: $e');
      return null;
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    try {
      final date = DateFormat('dd/MM/yyyy').parse(widget.kegiatan.tanggal);
      final timeParts = widget.kegiatan.waktu.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final eventDate = DateTime(date.year, date.month, date.day, hour, minute);
      _updateCountdown(eventDate);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown(eventDate));
    } catch (e) {
      debugPrint("Gagal parse tanggal/waktu: $e");
    }
  }

  void _updateCountdown(DateTime eventDate) {
    // intentionally left lightweight — not used for calculation here
  }

  Future<void> _ensureReminderScheduled() async {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(widget.kegiatan.tanggal);
      final timeParts = widget.kegiatan.waktu.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final eventDate = DateTime(date.year, date.month, date.day, hour, minute);
      final reminderTime = eventDate.subtract(const Duration(minutes: 30));

      if (reminderTime.isAfter(DateTime.now())) {
        final notifId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
        await notif_service.NotifikasiService.schedule(id: notifId, title: "Pengingat Kegiatan", body: "${widget.kegiatan.judul} — berangkat dalam 30 menit", date: reminderTime);
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && widget.kegiatan.docId != null) {
          await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('kegiatan').doc(widget.kegiatan.docId).set({'notifId': notifId.toString()}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Gagal schedule reminder: $e");
    }
  }

  Future<void> _bukaMapsExternal() async {
    try {
      // ambil posisi user saat ini (fallback ke _origin jika gagal)
      String asal;
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        asal = '${pos.latitude},${pos.longitude}';
      } catch (_) {
        if (_origin != null) {
          asal = '${_origin!.latitude},${_origin!.longitude}';
        } else {
          throw "Gagal mendapatkan lokasi perangkat";
        }
      }

      final tujuan = Uri.encodeComponent(widget.kegiatan.lokasi);
      final travelMode = (mode == "two_wheeler") ? "driving" : mode;
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$asal&destination=$tujuan&travelmode=$travelMode';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Tidak bisa membuka Google Maps";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka Google Maps: $e")));
      debugPrint("Error _bukaMapsExternal: $e");
    }
  }

  String _formatMinutesToDayHourMinute(int minutes) {
    if (minutes <= 0) return "0 menit";
    final days = minutes ~/ (24 * 60);
    final hours = (minutes % (24 * 60)) ~/ 60;
    final mins = minutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add("$days hari");
    if (hours > 0) parts.add("$hours jam");
    if (mins > 0) parts.add("$mins menit");
    return parts.join(' ');
  }

  double _averageSpeedKmhForMode(String mode) {
    switch (mode) {
      case 'walking':
        return 5.0;
      case 'bicycling':
        return 12.0;
      case 'two_wheeler':
        return 35.0;
      case 'driving':
      default:
        return 40.0;
    }
  }

  double _getTrafficMultiplier({
    required DateTime now,
    required String mode,
    String? kondisiCuaca,
    double userOverride = 1.0,
  }) {
    double base;
    switch (mode) {
      case 'walking':
        base = 1.0;
        break;
      case 'bicycling':
        base = 1.05;
        break;
      case 'two_wheeler':
        base = 1.1;
        break;
      case 'driving':
      default:
        base = 1.15;
        break;
    }

    final int hour = now.hour;
    final int weekday = now.weekday;
    double todFactor = 1.0;

    if (weekday >= 1 && weekday <= 5) {
      if (hour >= 6 && hour < 9) {
        todFactor = 1.35;
      } else if (hour >= 9 && hour < 16) {
        todFactor = 1.0;
      } else if (hour >= 16 && hour < 19) {
        todFactor = 1.45;
      } else if (hour >= 19 && hour < 22) {
        todFactor = 1.15;
      } else {
        todFactor = 0.95;
      }
    } else {
      if (hour >= 10 && hour < 14) {
        todFactor = 1.15;
      } else if (hour >= 18 && hour < 22) {
        todFactor = 1.1;
      } else {
        todFactor = 0.95;
      }
    }

    double weatherFactor = 1.0;
    if (kondisiCuaca != null) {
      final c = kondisiCuaca.toLowerCase();
      if (c.contains('rain') || c.contains('hujan') || c.contains('storm')) {
        weatherFactor = 1.2;
      } else if (c.contains('snow')) {
        weatherFactor = 1.35;
      } else if (c.contains('cloud') || c.contains('awan')) {
        weatherFactor = 1.05;
      } else {
        weatherFactor = 1.0;
      }
    }

    double combined = base * todFactor * weatherFactor * userOverride;
    const double minMultiplier = 0.8;
    const double maxMultiplier = 4.0;

    if (combined.isNaN || combined < minMultiplier) {
      combined = minMultiplier;
    } else if (combined > maxMultiplier) {
      combined = maxMultiplier;
    }

    return double.parse(combined.toStringAsFixed(2));
  }

  // User applies their own distance (km). We compute minutes and show suggestion: +30min buffer.
  Future<void> _applyUserDistance() async {
    final raw = _distanceController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Masukkan jarak dalam km (contoh: 12.5)")));
      return;
    }

    setState(() => _isApplyingDistance = true);

    try {
      final value = double.tryParse(raw.replaceAll(',', '.'));
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jarak tidak valid")));
        return;
      }

      final distanceKm = value;
      final speed = _averageSpeedKmhForMode(mode);
      final baseMinutes = (distanceKm / speed) * 60;

      final trafficMultiplier = _getTrafficMultiplier(now: DateTime.now(), mode: mode, kondisiCuaca: kondisiCuaca, userOverride: 1.0);

      final computedMinutes = max(1, (baseMinutes * trafficMultiplier).round());

      // 30 menit lebih awal
      final totalBefore = computedMinutes + 30;
      final suggestionText = "Berangkat ${_formatMinutesToDayHourMinute(totalBefore)} sebelum kegiatan";

      // update state lokal supaya UI langsung berubah
      setState(() {
        estimasiMinutes = computedMinutes;
        jarakKeTujuan = "${distanceKm.toStringAsFixed(1)} km (input)";
        estimasiWaktu = "${_formatMinutesToDayHourMinute(computedMinutes)} (berdasarkan jarak)";
      });

      // SIMPAN KE FIRESTORE
      final currentUser = FirebaseAuth.instance.currentUser;
      final docId = widget.kegiatan.docId;

      if (currentUser != null && docId != null && docId.isNotEmpty) {
        final updated = widget.kegiatan.copyWith(
          jarakManualKm: distanceKm,
          saranBerangkat: suggestionText,
          updatedAt: DateTime.now().toIso8601String(),
        );

        await _service.updateKegiatan(currentUser.uid, updated);
      }
    } catch (e) {
      debugPrint("Error applyUserDistance: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memproses jarak")));
      }
    } finally {
      if (mounted) setState(() => _isApplyingDistance = false);
    }
  }

  Future<void> _handleDelete() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah kamu yakin ingin menghapus kegiatan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isDeleting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login terlebih dahulu")));
        return;
      }

      final docId = widget.kegiatan.docId;
      if (docId == null || docId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DocId kegiatan tidak tersedia")));
        return;
      }

      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('kegiatan').doc(docId).get();
        if (snap.exists && snap.data() != null && snap.data()!['notifId'] != null) {
          final nid = int.tryParse(snap.data()!['notifId'].toString()) ?? 0;
          if (nid > 0) await notif_service.NotifikasiService.cancel(nid);
        }
      } catch (e) {
        debugPrint("Gagal cancel notif saat hapus (ignored): $e");
      }

      await _service.deleteKegiatan(currentUser.uid, docId);

      if (!mounted) return;
      Navigator.of(context).pop('done');
    } catch (e, st) {
      debugPrint("Gagal hapus kegiatan: $e\n$st");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus kegiatan: $e")));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _handleMarkDone() async {
    if (_isMarkingDone) return;
    setState(() => _isMarkingDone = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login terlebih dahulu")));
        return;
      }

      final docId = widget.kegiatan.docId;
      if (docId == null || docId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DocId kegiatan tidak tersedia")));
        return;
      }

      try {
        final snap = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).collection('kegiatan').doc(docId).get();
        if (snap.exists && snap.data() != null && snap.data()!['notifId'] != null) {
          final nid = int.tryParse(snap.data()!['notifId'].toString()) ?? 0;
          if (nid > 0) await notif_service.NotifikasiService.cancel(nid);
        }
      } catch (e) {
        debugPrint("Gagal cancel notif (ignored): $e");
      }

      final updated = widget.kegiatan.copyWith(status: "Selesai", updatedAt: DateTime.now().toIso8601String());
      await _service.updateKegiatan(currentUser.uid, updated);

      if (!mounted) return;
      Navigator.of(context).pop('done');
    } catch (e, st) {
      debugPrint("Gagal tandai selesai: $e\n$st");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menandai selesai: $e")));
    } finally {
      if (mounted) setState(() => _isMarkingDone = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavigatorFirebase()))),
        title: const Text("Detail Kegiatan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF64B5F6)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(kegiatan.judul, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(kegiatan.lokasi)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text("Tanggal: ${kegiatan.tanggal}"),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Text("Waktu: ${kegiatan.waktu}"),
              ]),
            ]),
          ),

          const SizedBox(height: 16),

          _buildCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Informasi Perjalanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Text("Data Google Maps", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _buildTransportOption(Icons.directions_walk, "walking"),
                _buildTransportOption(Icons.directions_bike, "bicycling"),
                _buildTransportOption(Icons.motorcycle, "two_wheeler"),
                _buildTransportOption(Icons.directions_car, "driving"),
              ]),
              const SizedBox(height: 12),

              Container(
                height: 220,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Stack(children: [
                  if (_initialCamera != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: _initialCamera!,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _markers,
                        polylines: Set<Polyline>.of(_polylines.values),
                        onMapCreated: (controller) async {
                          _mapController = controller;
                          // setelah controller siap, pastikan bounds di-fit (aman)
                          await _fitMapToBounds(polyPoints: _polylines.values.isNotEmpty ? _polylines.values.first.points : null);
                        },
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(jarakKeTujuan ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(estimasiWaktu ?? "-", style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 12),

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (jarakKeTujuan != null) Text("Jarak: $jarakKeTujuan"),
                      const SizedBox(height: 6),
                      Text("Klik untuk melihat rute")
                    ]),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _bukaMapsExternal,
                child: Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, color: Colors.blue, size: 28), Text("Lihat rute di Google Maps", style: TextStyle(color: Colors.blue))])),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Masukkan jarak rute (km) jika ingin menggunakan estimasi manual:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: "Contoh: 12.5", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isApplyingDistance ? null : _applyUserDistance,
                      child: _isApplyingDistance ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text("Gunakan"),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (estimasiMinutes != null)
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Saran berangkat ${_formatMinutesToDayHourMinute(estimasiMinutes! + 30)} sebelum kegiatan", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                    ])
                  else if (widget.kegiatan.saranBerangkat != null && widget.kegiatan.saranBerangkat!.isNotEmpty)
                    Text(widget.kegiatan.saranBerangkat!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange))
                  else
                    const SizedBox.shrink(),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          _buildCard(
            color: const Color(0xFFFFF7E5),
            borderColor: const Color(0xFFFFC107),
            child: Row(children: [
              Icon((kondisiCuaca ?? "").contains("rain") ? Icons.umbrella : Icons.lightbulb_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text((kondisiCuaca ?? "").contains("rain") ? "Hujan terdeteksi 🌧️. Siapkan jas hujan dan berangkat lebih awal!" : "Cuaca cerah ☀️. Waktu yang baik untuk beraktivitas!", style: const TextStyle(color: Colors.orange))),
            ]),
          ),

          if (kegiatan.catatan != null && kegiatan.catatan!.isNotEmpty)
            _buildCard(
              color: const Color(0xFF0D47A1),
              borderColor: Colors.transparent,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Catatan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(kegiatan.catatan!, style: const TextStyle(color: Colors.white)),
              ]),
            ),

          const SizedBox(height: 10),

          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
              icon: const Icon(Icons.edit, color: Colors.black),
              label: const Text("Edit", style: TextStyle(color: Colors.black)),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TambahKegiatanPageFirebase(kegiatan: kegiatan)));
                if (result == true && mounted) Navigator.pop(context, true);
              },
            ),
            _isDeleting
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>(Colors.red))),
                      SizedBox(width: 10),
                      Text('Menghapus...', style: TextStyle(color: Colors.red)),
                    ]),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, side: const BorderSide(color: Colors.red)),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                    onPressed: _handleDelete,
                  ),
          ]),

          const SizedBox(height: 12),

          Center(
            child: _isMarkingDone
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                      SizedBox(width: 10),
                      Text('Memproses...', style: TextStyle(color: Colors.white)),
                    ]),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Tandai Selesai"),
                    onPressed: _handleMarkDone,
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTransportOption(IconData icon, String value) {
    final isSelected = mode == value;
    return GestureDetector(
      onTap: () async {
        setState(() => mode = value);
        await _prepareMapAndRoute();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isSelected ? Colors.blue.shade100 : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300)),
        child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildCard({required Widget child, Color color = Colors.white, Color borderColor = Colors.transparent}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))]),
      child: child,
    );
  }
}
