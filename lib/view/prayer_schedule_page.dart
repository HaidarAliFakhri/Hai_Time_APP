import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class JadwalPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const JadwalPage({super.key, this.onBackToHome});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late Timer _timer;
  bool _adzanSedangBerbunyi = false;

  Map<String, dynamic>? nextPrayer;
  final FlutterLocalNotificationsPlugin _notifikasi =
      FlutterLocalNotificationsPlugin();

  final List<Map<String, dynamic>> jadwalSholat = [
    {
      "nama": "Subuh",
      "waktu": "04:45",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.brightness_2_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Dzuhur",
      "waktu": "11:42",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_sunny_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Ashar",
      "waktu": "14:55",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_twilight,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Magrib",
      "waktu": "17:47",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round_outlined,
      "aktif": true,
      "selesai": false,
    },
    {
      "nama": "Isya",
      "waktu": "18:59",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round,
      "aktif": true,
      "selesai": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    _initNotifikasi();
    _loadStatus(); // ✅ muat status aktif/tidak dari SharedPreferences
    _updateStatusSholat();
    _mintaIzinNotifikasi();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateStatusSholat();
    });

    _jadwalkanSemuaSholat();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// 🔔 Inisialisasi notifikasi lokal
  Future<void> _initNotifikasi() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await _notifikasi.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload == 'stop_adzan') {
        // 🔇 Matikan suara adzan
        if (_adzanSedangBerbunyi) {
          _adzanSedangBerbunyi = false;
          await _notifikasi.cancelAll(); // hentikan semua notifikasi aktif
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adzan dimatikan')),
          );
        }
      }
    },
  );
    // ✅ Tambahkan konfigurasi channel manual agar aman di Android <8
  const androidDetails = AndroidNotificationDetails(
    'adzan_channel',
    'Adzan Reminder',
    channelDescription: 'Notifikasi pengingat waktu sholat',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  // 🔔 Tes notifikasi untuk memastikan izin dan channel aktif
  await _notifikasi.show(
    999,
    'Notifikasi Siap ✅',
    'Sistem pengingat adzan aktif.',
    const NotificationDetails(android: androidDetails),
  );

}
    Future<void> _mintaIzinNotifikasi() async {
  final androidPlugin = _notifikasi.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();
}


  /// 💾 Simpan status switch ke SharedPreferences
  Future<void> _simpanStatus(String nama, bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aktif_$nama', aktif);
  }

  /// 📥 Muat status switch dari SharedPreferences saat pertama kali dibuka
  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var data in jadwalSholat) {
        final saved = prefs.getBool('aktif_${data["nama"]}');
        if (saved != null) {
          data["aktif"] = saved;
        }
      }
    });
  }

  /// 📅 Jadwalkan semua notifikasi adzan
  Future<void> _jadwalkanSemuaSholat() async {
    _adzanSedangBerbunyi = true;

    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    for (int i = 0; i < jadwalSholat.length; i++) {
      final data = jadwalSholat[i];
      if (data["aktif"] != true) continue; // ❗ Skip kalau dinonaktifkan

      final waktu = format.parse(data["waktu"]);
      final waktuHariIni = DateTime(
        now.year,
        now.month,
        now.day,
        waktu.hour,
        waktu.minute,
      );

      final waktuFinal = now.isAfter(waktuHariIni)
          ? waktuHariIni.add(const Duration(days: 1))
          : waktuHariIni;

      await _notifikasi.zonedSchedule(
  i,
  "Waktu Sholat ${data["nama"]}",
  "Sudah masuk waktu ${data["nama"]}. Ayo sholat dulu 🕌",
  tz.TZDateTime.from(waktuFinal, tz.local),
  NotificationDetails(
    android: AndroidNotificationDetails(
      'adzan_channel',
      'Adzan Reminder',
      channelDescription: 'Notifikasi pengingat waktu sholat',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('adzan'),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_adzan', // id unik
          'Matikan Adzan 🔇',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    ),
  ),
  payload: 'stop_adzan',
  androidAllowWhileIdle: true,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
);
    }
  }

  /// 🕒 Update status sholat di UI
  void _updateStatusSholat() {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    setState(() {
      for (var data in jadwalSholat) {
        final waktuSholat = format.parse(data["waktu"]);
        final waktuHariIni = DateTime(
          now.year,
          now.month,
          now.day,
          waktuSholat.hour,
          waktuSholat.minute,
        );
        data["selesai"] = now.isAfter(waktuHariIni);
      }

      nextPrayer = jadwalSholat.firstWhere((data) {
        final waktu = format.parse(data["waktu"]);
        final waktuHariIni = DateTime(
          now.year,
          now.month,
          now.day,
          waktu.hour,
          waktu.minute,
        );
        return now.isBefore(waktuHariIni);
      }, orElse: () => jadwalSholat.last);
    });
  }

  /// ⏳ Hitung sisa waktu menuju sholat berikutnya
  String _hitungSisaWaktu(String waktu) {
    final now = DateTime.now();
    final format = DateFormat("HH:mm");
    final waktuSholat = format.parse(waktu);
    final waktuHariIni = DateTime(
      now.year,
      now.month,
      now.day,
      waktuSholat.hour,
      waktuSholat.minute,
    );

    final diff = waktuHariIni.difference(now);
    if (diff.isNegative) return "Sudah lewat";

    final jam = diff.inHours;
    final menit = diff.inMinutes % 60;
    return "Dalam ${jam > 0 ? '$jam jam ' : ''}$menit menit";
  }

  @override
  Widget build(BuildContext context) {
    final currentNext = nextPrayer ?? jadwalSholat[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3FA9F5), Color(0xFF0077FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          widget.onBackToHome?.call();
                        }
                      },
                      tooltip: 'Kembali',
                      iconSize: 26,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Icon(Ionicons.moon_outline,
                      color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "Jadwal Sholat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat("EEEE, d MMMM yyyy", "id_ID")
                        .format(DateTime.now()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A00),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Waktu Sholat Berikutnya",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(currentNext["nama"],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(_hitungSisaWaktu(currentNext["waktu"]),
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Text(
                          currentNext["waktu"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(jadwalSholat.length, (index) {
                  final data = jadwalSholat[index];
                  return Column(
                    children: [
                      _buildPrayerCard(
                        data["nama"],
                        data["waktu"],
                        data["pengingat"],
                        data["ikon"],
                        data["aktif"],
                        data["selesai"],
                        highlight: data == nextPrayer,
                        onChanged: (val) {
                          setState(() {
                            data["aktif"] = val;
                          });
                          _simpanStatus(data["nama"], val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(
    String title,
    String time,
    String subtitle,
    IconData icon,
    bool isOn,
    
    bool done, {
    bool highlight = false,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: highlight ? Colors.orange : Colors.blue, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text(
                  done ? "✔ Sudah dilaksanakan" : "Belum dilaksanakan",
                  style: TextStyle(
                    color: done ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Switch(
                value: isOn,
                activeColor: Colors.blue,
                inactiveThumbColor: Colors.grey,
                onChanged: (val) => onChanged(val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
