// lib/page/kalender_page_firebase.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hai_time_app/services/weather_service.dart';
import 'package:hai_time_app/services/activity_service.dart'; // KegiatanService
import 'package:hai_time_app/model/activitymodel.dart'; // KegiatanFirebase model
import 'package:hai_time_app/view/activity_page_firebase.dart'; // KegiatanPageFirebase
import 'package:hai_time_app/view/add_activities_firebase.dart'; // TambahKegiatanPageFirebase

class KalenderPageFirebase extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const KalenderPageFirebase({super.key, this.onBackToHome});

  @override
  State<KalenderPageFirebase> createState() => _KalenderPageFirebaseState();
}

class _KalenderPageFirebaseState extends State<KalenderPageFirebase> {
  final KegiatanService _service = KegiatanService();
  final user = FirebaseAuth.instance.currentUser;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // events cache sama seperti di HomePage untuk performa
  Map<DateTime, List<KegiatanFirebase>> _eventsCache = {};
  String _eventsCacheKey = "";

  late Future<Map<String, dynamic>?> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchWeather();
    // timer untuk update rerender jika perlu
    Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  // --- UTIL: normalisasi tanggal untuk grouping (sama dengan HomePage) ---
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseTanggal(String? tanggalStr, {String? waktu}) {
    if (tanggalStr == null || tanggalStr.trim().isEmpty) return null;
    final formats = [
      DateFormat("yyyy-MM-dd"),
      DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
      DateFormat("dd/MM/yyyy"),
      DateFormat("dd-MM-yyyy"),
      DateFormat.yMd(),
    ];
    for (final f in formats) {
      try {
        return _normalize(f.parse(tanggalStr));
      } catch (_) {}
    }
    try {
      return _normalize(DateTime.parse(tanggalStr));
    } catch (_) {}
    if (waktu != null && waktu.isNotEmpty) {
      try {
        return _normalize(DateTime.parse(waktu));
      } catch (_) {}
    }
    return null;
  }

  bool _isKegiatanSelesaiModel(KegiatanFirebase k) {
  final st = k.status.trim().toLowerCase();
  return st == 'selesai' || st == 'done' || st == 'completed';
}

  bool _isKegiatanTerlewat(KegiatanFirebase k) {
  try {
    final tgl = _parseTanggal(k.tanggal, waktu: k.createdAt);
    if (tgl == null) return false;

    // parse waktu HH:mm
    final parts = k.waktu.split(":");
    final jam = int.tryParse(parts[0]) ?? 0;
    final menit = int.tryParse(parts[1]) ?? 0;

    final dt = DateTime(tgl.year, tgl.month, tgl.day, jam, menit);

    // gunakan helper untuk cek selesai
    return dt.isBefore(DateTime.now()) && !_isKegiatanSelesaiModel(k);
  } catch (_) {
    return false;
  }
}

  void _buildEventsCache(List<KegiatanFirebase> list) {
    final newKey = list.map((e) => (e.docId ?? '') + '_' + (e.updatedAt ?? '')).join('|');
    if (newKey == _eventsCacheKey) return;
    _eventsCacheKey = newKey;
    _eventsCache = {};
    for (final k in list) {
      if (_isKegiatanSelesaiModel(k)) continue;
      final parsed = _parseTanggal(k.tanggal, waktu: k.createdAt);
      if (parsed == null) continue;
      final key = _normalize(parsed);
      _eventsCache.putIfAbsent(key, () => []);
      _eventsCache[key]!.add(k);
    }
  }

  // --- WIDGET: Card helper ---
  Widget _buildCard({String? title, Widget? trailing, required Widget child, Color color = Colors.white}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (trailing != null) trailing,
          ]),
        if (title != null) const SizedBox(height: 8),
        child,
      ]),
    );
  }

  // --- WEATHER ADVICE CARD (dipindah dari HomePage) ---
  Widget _buildWeatherAdviceCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _weatherFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            color: const Color(0xFFFFF6E5),
            child: const ListTile(
              leading: Icon(Icons.cloud_queue, color: Colors.orange),
              title: Text("Mengambil data cuaca..."),
              subtitle: Text("Tunggu sebentar ya ☁️"),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildCard(
            color: const Color(0xFFFFE5E5),
            child: const ListTile(
              leading: Icon(Icons.error, color: Colors.redAccent),
              title: Text("Gagal memuat cuaca"),
              subtitle: Text("Pastikan koneksi internetmu aktif 🌐"),
            ),
          );
        }

        final data = snapshot.data!;
        final condition = data['weather'][0]['main'].toString().toLowerCase();
        IconData icon;
        String title;
        String message;
        Color bgColor;

        if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('thunderstorm')) {
          icon = Icons.umbrella;
          title = "Cuaca sedang hujan 🌧️";
          message = "Bawa payung dan berangkat lebih awal ya.";
          bgColor = const Color(0xFFE3F2FD);
        } else if (condition.contains('cloud')) {
          icon = Icons.cloud;
          title = "Cuaca mendung ☁️";
          message = "Pertimbangkan berangkat lebih awal untuk kegiatan sore ini.";
          bgColor = const Color(0xFFFFF6E5);
        } else if (condition.contains('snow')) {
          icon = Icons.ac_unit;
          title = "Turun salju ❄️";
          message = "Kenakan pakaian hangat agar tetap nyaman.";
          bgColor = const Color(0xFFE1F5FE);
        } else {
          icon = Icons.wb_sunny;
          title = "Cuaca cerah ☀️";
          message = "Cuaca bagus! Waktu yang tepat untuk beraktivitas.";
          bgColor = const Color(0xFFE8F5E9);
        }

        return _buildCard(
          color: bgColor,
          child: ListTile(
            leading: Icon(icon, color: Colors.orange),
            title: Text(title),
            subtitle: Text(message),
          ),
        );
      },
    );
  }

  // --- KEGIATAN CARD (kalender + event list) ---
  Widget _buildKegiatanCard() {
  if (user == null) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 12, 158, 255), Color.fromARGB(255, 67, 64, 221)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Silakan login untuk melihat kegiatan.",
        style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
      ),
    );
  }

  return StreamBuilder<List<KegiatanFirebase>>(
    stream: _service.getKegiatanUser(user!.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color.fromARGB(255, 122, 213, 255)),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        // reset cache when no data
        _eventsCache = {};
        _eventsCacheKey = "";
        return Container(
          padding: const EdgeInsets.all(35),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 49, 128, 247),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            "Belum ada kegiatan.\nTambahkan kegiatanmu sekarang!",
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      final kegiatanList = snapshot.data!;

      // BUILD / REUSE CACHE
      _buildEventsCache(kegiatanList);

      // hitung kegiatan aktif untuk header-count
      final kegiatanAktif = kegiatanList.where((k) => !_isKegiatanSelesaiModel(k)).toList();

      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Kegiatan Anda",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 52, 141, 243),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${kegiatanAktif.length} Kegiatan",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Calendar with markers
            TableCalendar<KegiatanFirebase>(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && _normalize(day) == _normalize(_selectedDay!),
              eventLoader: (day) {
                return _eventsCache[_normalize(day)] ?? [];
              },
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selectedDay, focusedDay) {
                // jika klik tanggal yang sama -> jangan setState (hindari rebuild)
                if (_selectedDay != null && _normalize(selectedDay) == _normalize(_selectedDay!)) {
                  _focusedDay = focusedDay;
                  return;
                }

                // setState hanya ketika seleksi tanggal berubah
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                markerDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final dayEvents = _eventsCache[_normalize(date)];
                  if (dayEvents == null || dayEvents.isEmpty) return const SizedBox.shrink();

                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 12, 0, 180),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Jika ada events pada selected day -> tampilkan satu card per kegiatan (gabungkan saran di dalamnya)
            if (_selectedDay != null && (_eventsCache[_normalize(_selectedDay!)]?.isNotEmpty ?? false))
              _buildCard(
                child: Builder(builder: (context) {
                  final key = _normalize(_selectedDay!);
                  final dayEvents = List<KegiatanFirebase>.from(_eventsCache[key] ?? <KegiatanFirebase>[]);
                  final activeEvents = dayEvents.where((k) => !_isKegiatanSelesaiModel(k)).toList();

                  // jika tidak ada event aktif
                  if (activeEvents.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // tampilkan satu card per kegiatan, masing-masing card berisi judul, waktu, lokasi, saran
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text("Ringkasan hari ini:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Gantikan bagian mapping activeEvents.map(...) dengan kode ini:
                      Column(
                        children: activeEvents.map((k) {
                          final terlewat = _isKegiatanTerlewat(k);
                          return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Material(
                          color: const Color.fromARGB(169, 147, 224, 255),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KegiatanPageFirebase(kegiatan: k),
                                ),
                              );
                            },

                            // CHILD HARUS PALING BAWAH
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Judul + status
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          k.judul,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      if (terlewat)
                                        const Icon(Icons.schedule, color: Colors.red, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Jam + lokasi
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Text(k.waktu, style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.blueGrey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          k.lokasi,
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // saran keberangkatan
                                  if (k.saranBerangkat != null &&
                                      k.saranBerangkat!.trim().isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.shade100),
                                      ),
                                      child: Text(
                                        k.saranBerangkat!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );

                      }).toList(),
                    ),

                    ],
                  );
                }),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kalender & Cuaca"),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //               onPressed: () {
        //                 Navigator.pop(context); // kembali ke HomePageFirebase
        //   },
        // ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Weather advice pertama
          _buildWeatherAdviceCard(),
          const SizedBox(height: 20),
          // Kegiatan / Kalender
          _buildKegiatanCard(),
          const SizedBox(height: 20),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () async {
          // buka halaman tambah kegiatan (sama seperti HomePage)
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const TambahKegiatanPageFirebase()));
          if (result == true && mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
