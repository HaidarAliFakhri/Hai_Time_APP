// lib/pages/kegiatan_page_firebase.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hai_time_app/model/activitymodel.dart';
import 'package:hai_time_app/services/activity_service.dart';
import 'package:hai_time_app/services/weather_service.dart';
import 'package:hai_time_app/view/add_activities_firebase.dart';
import 'package:hai_time_app/services/notification_service.dart' as notif_service;
import 'package:url_launcher/url_launcher.dart';

const String kGoogleApiKey =
    'AIzaSyDk_IqTjxDnhlwFcVf8bYfNR0qBtEGAyJw'; // gunakan API key Anda

class KegiatanPageFirebase extends StatefulWidget {
  final KegiatanFirebase kegiatan;

  const KegiatanPageFirebase({super.key, required this.kegiatan});

  @override
  State<KegiatanPageFirebase> createState() => _KegiatanPageFirebaseState();
}

class _KegiatanPageFirebaseState extends State<KegiatanPageFirebase> {
  final _service = KegiatanService();

  // Loading & estimasi
  bool loading = false;
  String? estimasiWaktu; // example: "15 mins"
  String? jarakKeTujuan; // example: "3.4 km"
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
  

  // Countdown & reminder
  Timer? _countdownTimer;
  Duration _timeToEvent = Duration.zero;

  // Misc
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
    super.dispose();
  }

  Future<void> _initAll() async {
    // start with loading map & route & weather & countdown
    await _loadWeather();
    await _prepareMapAndRoute();
    _startCountdown();
    _ensureReminderScheduled();
  }

  // ---------------------------
  // WEATHER
  // ---------------------------
  Future<void> _loadWeather() async {
    try {
      final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
      final dest = lokasiTujuan.first;

      final cuaca = await WeatherService.getWeather(
        dest.latitude,
        dest.longitude,
      );

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

  // ---------------------------
  // MAPS, DIRECTIONS & POLYLINE
  // ---------------------------
  Future<void> _prepareMapAndRoute() async {
  setState(() => loading = true);

  try {
    // 1) Lokasi saat ini
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 2) Lokasi tujuan (dari alamat)
    final lokasiTujuan = await locationFromAddress(widget.kegiatan.lokasi);
    final dest = lokasiTujuan.first;

    _origin = LatLng(pos.latitude, pos.longitude);
    _dest = LatLng(dest.latitude, dest.longitude);

    // Setup kamera tengah
    final centerLat = (_origin!.latitude + _dest!.latitude) / 2;
    final centerLng = (_origin!.longitude + _dest!.longitude) / 2;
    _initialCamera = CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: 12,
    );

    // Marker
    _markers.clear();
    _markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: _origin!,
      infoWindow: const InfoWindow(title: 'Lokasimu'),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('dest'),
      position: _dest!,
      infoWindow: InfoWindow(title: widget.kegiatan.lokasi),
    ));

    // 3) Fetch Directions API
    final directions = await _fetchDirections(
      _origin!.latitude,
      _origin!.longitude,
      _dest!.latitude,
      _dest!.longitude,
      travelMode: mode == "two_wheeler" ? "driving" : mode,
    );

    if (directions != null) {
      final route = directions['routes'][0];
      final leg = route['legs'][0];

      final distanceText = leg['distance']?['text'] ?? '';
      final durationText = leg['duration']?['text'] ?? '';

      // ✅ AMBIL POLYLINE YANG BENAR
      final encodedPolyline = route['overview_polyline']?['points'];

      if (encodedPolyline != null) {
  // ✅ Decode polyline
  final decodedPoints = PolylinePoints.decodePolyline(encodedPolyline);

  final points = decodedPoints
      .map((p) => LatLng(p.latitude, p.longitude))
      .toList();

  final id = const PolylineId('route_poly');
  final poly = Polyline(
    polylineId: id,
    points: points,
    color: Colors.blue,
    width: 5,
  );

  setState(() {
    estimasiWaktu = durationText;
    jarakKeTujuan = distanceText;
    _polylines.clear();
    _polylines[id] = poly;
  });

  // ✅ Auto fit kamera
  if (_mapController != null && points.isNotEmpty) {
    final swLat = points.map((e) => e.latitude).reduce(min);
    final swLng = points.map((e) => e.longitude).reduce(min);
    final neLat = points.map((e) => e.latitude).reduce(max);
    final neLng = points.map((e) => e.longitude).reduce(max);

    final bounds = LatLngBounds(
      southwest: LatLng(swLat, swLng),
      northeast: LatLng(neLat, neLng),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }
}

    } else {
      // ✅ fallback jarak garis lurus
      final jarakKm = _calculateDistance(
        _origin!.latitude,
        _origin!.longitude,
        _dest!.latitude,
        _dest!.longitude,
      );

      final estimatedMin = (jarakKm / 60 * 60).round();

      setState(() {
        estimasiWaktu = "$estimatedMin menit (perkiraan)";
        jarakKeTujuan = "${jarakKm.toStringAsFixed(1)} km";
      });
    }
  } catch (e) {
    debugPrint("Error prepareMapAndRoute: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat rute")),
      );
    }
  } finally {
    setState(() => loading = false);
  }
}


  Future<Map<String, dynamic>?> _fetchDirections(
    double originLat,
    double originLng,
    double destLat,
    double destLng, {
    String travelMode = "driving",
  }) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&mode=$travelMode'
        '&key=$kGoogleApiKey',
      );

      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(resp.body);
      if (data['status'] != 'OK') {
        debugPrint('Directions API status: ${data['status']} - ${data['error_message']}');
        return null;
      }
      return data;
    } catch (e) {
      debugPrint('Fetch directions error: $e');
      return null;
    }
  }

  // ---------------------------
  // COUNTDOWN & REMINDER
  // ---------------------------
  void _startCountdown() {
    _countdownTimer?.cancel();

    // target date -> parse tanggal (dd/MM/yyyy) + waktu (HH:mm)
    try {
      final date = DateFormat('dd/MM/yyyy').parse(widget.kegiatan.tanggal);
      final timeParts = widget.kegiatan.waktu.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;

      final eventDate = DateTime(date.year, date.month, date.day, hour, minute);
      _updateCountdown(eventDate);

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateCountdown(eventDate);
      });
    } catch (e) {
      debugPrint("Gagal parse tanggal/waktu: $e");
    }
  }

  void _updateCountdown(DateTime eventDate) {
    final now = DateTime.now();
    final diff = eventDate.difference(now);
    setState(() {
      _timeToEvent = diff.isNegative ? Duration.zero : diff;
    });
  }

  Future<void> _ensureReminderScheduled() async {
    // schedule local notification 30 minutes before event (if in future)
    try {
      final date = DateFormat('dd/MM/yyyy').parse(widget.kegiatan.tanggal);
      final timeParts = widget.kegiatan.waktu.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final eventDate = DateTime(date.year, date.month, date.day, hour, minute);
      final reminderTime = eventDate.subtract(Duration(minutes: 30));

      if (reminderTime.isAfter(DateTime.now())) {
        final notifId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

        await notif_service.NotifikasiService.schedule(
          id: notifId,
          title: "Pengingat Kegiatan",
          body: "${widget.kegiatan.judul} — berangkat dalam 30 menit",
          date: reminderTime,
        );

        // simpan notifId ke Firestore agar bisa dibatalkan saat edit/hapus
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && widget.kegiatan.docId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('kegiatan')
              .doc(widget.kegiatan.docId)
              .set({'notifId': notifId.toString()}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint("Gagal schedule reminder: $e");
    }
  }

  // ---------------------------
  // OPEN EXTERNAL GOOGLE MAPS (fallback)
  // ---------------------------
  Future<void> _bukaMapsExternal() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final asal = '${pos.latitude},${pos.longitude}';
      final tujuan = Uri.encodeComponent(widget.kegiatan.lokasi);
      final travelMode = mode == "two_wheeler" ? "driving" : mode;
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$asal&destination=$tujuan&travelmode=$travelMode';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "Tidak bisa membuka Google Maps";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal membuka Google Maps: $e")));
    }
  }

  // ---------------------------
  // HELPER UTILITY
  // ---------------------------
  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371;
    var dLat = (lat2 - lat1) * pi / 180;
    var dLon = (lon2 - lon1) * pi / 180;
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  

  // ---------------------------
  // UI BUILD
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final kegiatan = widget.kegiatan;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Kegiatan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
            // CARD INFO KEGIATAN (preserve design)
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

            // CARD PERJALANAN + MAP
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header + badge Google Maps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Informasi Perjalanan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("Data Google Maps", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // transport option row (same design)
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

                  // Map area
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        if (_initialCamera != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GoogleMap(
                              initialCameraPosition: _initialCamera!,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              markers: _markers,
                              polylines: Set<Polyline>.of(_polylines.values),
                              onMapCreated: (controller) {
                                _mapController = controller;
                                // optionally animate after creation if polylines exist
                              },
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),

                        // top-right small badge with distance & duration
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(jarakKeTujuan ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(estimasiWaktu ?? "-", style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mode: ${modeLabel[mode]}"),
                            if (jarakKeTujuan != null) Text("Jarak ke Tujuan: $jarakKeTujuan"),
                            Text("Estimasi: ${estimasiWaktu ?? '-'}"),
                            Text(
                              "Waktu Ideal: ${_timeToEvent == Duration.zero ? '-' : _calcWaktuIdeal()}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),

                  const SizedBox(height: 12),

                  // tombol membuka google maps external
                  GestureDetector(
                    onTap: _bukaMapsExternal,
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

            const SizedBox(height: 8),

            // SARAN DINAMIS (CUACA)
            _buildCard(
              color: const Color(0xFFFFF7E5),
              borderColor: const Color(0xFFFFC107),
              child: Row(
                children: [
                  Icon(
                    (kondisiCuaca ?? "").contains("rain") ? Icons.umbrella : Icons.lightbulb_outline,
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

            // CATATAN, TOMBOL EDIT/HAPUS/TANDAI SELESAI (preserve)
            if (kegiatan.catatan != null && kegiatan.catatan!.isNotEmpty)
              _buildCard(
                color: const Color(0xFF0D47A1),
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Catatan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(kegiatan.catatan!, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text("Edit", style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TambahKegiatanPageFirebase(kegiatan: kegiatan)),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0, side: const BorderSide(color: Colors.red)),
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
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (konfirmasi == true) {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login terlebih dahulu")));
                        return;
                      }

                      final docId = widget.kegiatan.docId;
                      if (docId == null || docId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DocId kegiatan tidak tersedia")));
                        return;
                      }

                      // cancel scheduled notif if any
                      try {
                        final snap = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .collection('kegiatan')
                            .doc(docId)
                            .get();
                        if (snap.exists && snap.data() != null && snap.data()!['notifId'] != null) {
                          final nid = int.tryParse(snap.data()!['notifId'].toString()) ?? 0;
                          if (nid > 0) await notif_service.NotifikasiService.cancel(nid);
                        }
                      } catch (e) {
                        debugPrint("Gagal cancel notif saat hapus: $e");
                      }

                      await _service.deleteKegiatan(currentUser.uid, docId);
                      if (mounted) Navigator.pop(context, true);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Tandai Selesai"),
                onPressed: () async {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login terlebih dahulu")));
                    return;
                  }
                  final updated = widget.kegiatan.copyWith(status: "Selesai", updatedAt: DateTime.now().toIso8601String());
                  await _service.updateKegiatan(currentUser.uid, updated);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Kegiatan ditandai sebagai selesai")));
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

  String _calcWaktuIdeal() {
    // tampilkan rekomendasi singkat berdasarkan estimasi atau countdown
    try {
      if (estimasiWaktu != null && estimasiWaktu!.isNotEmpty) {
        // gunakan estimasi yang tersedia (mis: "15 mins")
        return "Berangkat 30 menit sebelum kegiatan";
      } else {
        // fallback: gunakan _timeToEvent
        final minutes = _timeToEvent.inMinutes;
        if (minutes > 60) return "Berangkat 45 menit sebelum kegiatan";
        return "Berangkat 30 menit sebelum kegiatan";
      }
    } catch (_) {
      return "Berangkat 30 menit sebelum kegiatan";
    }
  }

  // ---------------------------
  // SMALL WIDGETS (reuse design)
  // ---------------------------
  Widget _buildTransportOption(IconData icon, String value) {
    final isSelected = mode == value;

    return GestureDetector(
      onTap: () async {
        setState(() {
          mode = value;
        });
        await _prepareMapAndRoute();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
        ),
        child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 28),
      ),
    );
  }

  Widget _buildCard({required Widget child, Color color = Colors.white, Color borderColor = Colors.transparent}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}
