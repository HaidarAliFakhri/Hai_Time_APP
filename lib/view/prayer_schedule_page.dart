// lib/pages/jadwal_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hai_time_app/utils/notification_adzan.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Halaman Jadwal Sholat + scheduling adzan
class JadwalPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const JadwalPage({super.key, this.onBackToHome});

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late Timer _timer;


  Map<String, dynamic>? nextPrayer;
  final FlutterLocalNotificationsPlugin _notifikasi =
      FlutterLocalNotificationsPlugin();

  // DEFAULT: semua OFF (sesuai permintaan)
  final List<Map<String, dynamic>> jadwalSholat = [
    {
      "nama": "Subuh",
      "waktu": "04:45",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.brightness_2_outlined,
      "aktif": false,
      "selesai": false,
    },
    {
      "nama": "Dzuhur",
      "waktu": "11:42",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_sunny_outlined,
      "aktif": false,
      "selesai": false,
    },
    {
      "nama": "Ashar",
      "waktu": "14:55",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.wb_twilight,
      "aktif": false,
      "selesai": false,
    },
    {
      "nama": "Magrib",
      "waktu": "17:47",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round_outlined,
      "aktif": false,
      "selesai": false,
    },
    {
      "nama": "Isya",
      "waktu": "18:59",
      "pengingat": "10 menit sebelumnya",
      "ikon": Icons.nightlight_round,
      "aktif": false,
      "selesai": false,
    },
  ];

  // channel id constant — gunakan v2 agar tidak terpengaruh channel lama
  static const String _channelId = 'adzan_channel_v2';
  static const String _channelName = 'Adzan Reminder';
  static const String _channelDesc = 'Notifikasi pengingat waktu sholat';

  @override
  void initState() {
    super.initState();
    // timezone
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}

    _initNotifikasi();
    _loadStatus().then((_) {
      // Setelah load status, update UI dan schedule sesuai status
      _updateStatusSholat();
      _jadwalkanSemuaSholat();
    });

    // cek tiap 30 detik supaya lebih responsif (tapi jangan spaming)
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateStatusSholat();
      _checkAndTriggerImmediateNotification();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Inisialisasi plugin notifikasi
  Future<void> _initNotifikasi() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Aktifkan requestSoundPermission agar iOS boleh memutar suara
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _notifikasi.initialize(
  initSettings,
  onDidReceiveNotificationResponse: (NotificationResponse response) async {
    // Cek berdasarkan actionId (BENAR untuk tombol "Matikan Adzan")
    final actionId = response.actionId;

    if (actionId == 'stop_adzan') {
      // Jika audio sedang diputar, stop melalui service global
      if (AdzanService.instance.isPlaying) {
        try {
          await AdzanService.instance.stop();
        } catch (e) {
          debugPrint('Error stopping adzan: $e');
        }

        // Batalkan semua notifikasi adzan yang masih tampil
        try {
          await _notifikasi.cancelAll();
        } catch (e) {
          debugPrint('cancelAll failed: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adzan dimatikan')),
          );
        }
      }
    }
  },
  onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
);


    // create android channel (required Android 8+)
    if (Platform.isAndroid) {
      final androidPlugin = _notifikasi
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('adzan'),
        );
        try {
          await androidPlugin.createNotificationChannel(channel);
          debugPrint('Created/updated channel: $_channelId with sound adzan');
        } catch (e) {
          debugPrint('createNotificationChannel error: $e');
        }
      } else {
        debugPrint('Android plugin impl is null — cannot create channel');
      }
    }

    // request permissions
    await _requestPermissions();
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    try {
      debugPrint('Background notification tapped: ${response.payload}');
    } catch (e) {
      debugPrint('background handler error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notifikasi
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      try {
        await androidImpl?.requestNotificationsPermission();
      } catch (e) {
        debugPrint('requestNotificationsPermission failed: $e');
        try {
          final status = await Permission.notification.status;
          if (!status.isGranted) await Permission.notification.request();
        } catch (e2) {
          debugPrint('permission_handler fallback failed: $e2');
        }
      }

      try {
        await androidImpl?.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('requestExactAlarmsPermission not available or failed: $e');
      }
    }

    if (Platform.isIOS) {
      final iosImpl = _notifikasi
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      try {
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('iOS requestPermissions failed: $e');
      }
    }
  }

  /// Simpan status switch ke SharedPreferences
  Future<void> _simpanStatus(String nama, bool aktif) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aktif_$nama', aktif);
  }

  /// Muat status switch dari SharedPreferences
  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var data in jadwalSholat) {
        final saved = prefs.getBool('aktif_${data["nama"]}');
        // default false jika belum ada
        data["aktif"] = saved ?? false;
      }
    });
  }

  /// Batalkan semua jadwal lama lalu schedule ulang semua notifikasi
  Future<void> _jadwalkanSemuaSholat() async {
    // batalkan dulu untuk mencegah duplicate
    try {
      await _notifikasi.cancelAll();
    } catch (e) {
      debugPrint('cancelAll failed: $e');
    }

    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    for (int i = 0; i < jadwalSholat.length; i++) {
      final data = jadwalSholat[i];
      if (data["aktif"] != true) continue;

      final waktu = format.parse(data["waktu"]);
      final waktuHariIni = DateTime(
        now.year,
        now.month,
        now.day,
        waktu.hour,
        waktu.minute,
      );

      final scheduledDate = now.isAfter(waktuHariIni)
          ? waktuHariIni.add(const Duration(days: 1))
          : waktuHariIni;

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('adzan'),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'stop_adzan',
            'Matikan Adzan 🔇',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final darwinDetails = DarwinNotificationDetails(
        sound: 'adzan.aiff',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final String title = "Waktu Sholat ${data['nama']}";
      final String body =
          "Sudah masuk waktu ${data['nama']}. Ayo sholat dulu 🕌";
      final String payload = "adzan_${data['nama']}";

      try {
        await _notifikasi.zonedSchedule(
          i, // id = index
          title,
          body,
          tzScheduled,
          details,
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('Scheduled ${data['nama']} at $tzScheduled (id=$i)');
      } catch (e) {
        debugPrint('zonedSchedule failed for ${data["nama"]}: $e');
      }
    }
  }

  /// Cek tiap interval; jika waktu sekarang tepat sama dengan salah satu jadwal (HH:mm),
  /// trigger notifikasi segera (berguna jika sistem tidak mengeksekusi zonedSchedule tepat waktu)
  void _checkAndTriggerImmediateNotification() {
  final now = DateTime.now();
  final current = DateFormat('HH:mm').format(now);

  for (var data in jadwalSholat) {
    if (data['aktif'] != true) continue;
    final waktu = data['waktu'] as String;
    if (waktu == current) {
      // gunakan nama + tanggal untuk uniqueness
      _showAdzanNow(data['nama']);
    }
  }
}


  /// Tampilkan notifikasi adzan segera (digunakan oleh check immediate)
  Future<void> _showAdzanNow(String nama) async {
  final now = DateTime.now();
  final key = DateFormat('yyyy-MM-dd|HH:mm').format(now); // unik per menit
  if (!AdzanService.instance.markTriggered(key)) {
    debugPrint('Already triggered for $key -> skip');
    return;
  }

  if (AdzanService.instance.isPlaying) {
    debugPrint('Adzan already playing globally -> skip');
    return;
  }

  // mulai audio (asset path: sesuaikan; jika kamu punya assets/adzan.mp3 -> 'adzan.mp3')
  AdzanService.instance.playAsset('adzan.mp3');

  // Tampilkan notifikasi (tetap diperlukan untuk tombol stop)
  final androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    sound: const RawResourceAndroidNotificationSound('adzan'),
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'stop_adzan', // actionId
        'Matikan Adzan 🔇',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
    // Opsi tambahan agar notif lebih "persistent" sampai user stop:
    ongoing: true,
    autoCancel: false,
  );

  final darwinDetails = DarwinNotificationDetails(
    sound: 'adzan.aiff',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: darwinDetails);

  try {
    await _notifikasi.show(
      generateSafeNotifId(),
      'Waktu Sholat $nama',
      'Sudah masuk waktu $nama. Ayo sholat dulu 🕌',
      details,
      payload: 'adzan_$nama',
    );

    // Biarkan AdzanService yang mengatur durasi; kalau mau reset flag setelah X
    // AdzanService.instance akan update isPlaying=false di stop()
  } catch (e) {
    debugPrint('show immediate notification failed: $e');
  }
}


  /// Generate safe 32-bit id
  int generateSafeNotifId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return (ms % 2147483647).toInt();
  }

  /// Update status sholat di UI (sudah lewat / belum)
  void _updateStatusSholat() {
    final now = DateTime.now();
    final fmt = DateFormat('HH:mm');

    setState(() {
      for (var data in jadwalSholat) {
        final waktu = fmt.parse(data['waktu'] as String);
        final waktuHariIni = DateTime(
          now.year,
          now.month,
          now.day,
          waktu.hour,
          waktu.minute,
        );
        data['selesai'] = now.isAfter(waktuHariIni);
      }

      nextPrayer = jadwalSholat.firstWhere((data) {
        final waktu = fmt.parse(data['waktu'] as String);
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
            // HEADER
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
                  // Align(
                  //   alignment: Alignment.topLeft,
                  //   child: IconButton(
                  //     icon: const Icon(Icons.arrow_back, color: Colors.white),
                  //     onPressed: () {
                  //       Navigator.pop(context);
                  //     },
                  //   ),
                  // ),
                  const SizedBox(height: 10),
                  const Icon(
                    Ionicons.moon_outline,
                    color: Colors.white,
                    size: 60,
                  ),
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
                    DateFormat(
                      "EEEE, d MMMM yyyy",
                      "id_ID",
                    ).format(DateTime.now()),
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
                            const Text(
                              "Waktu Sholat Berikutnya",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentNext["nama"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _hitungSisaWaktu(currentNext["waktu"]),
                              style: const TextStyle(color: Colors.white70),
                            ),

                            //test adzan
                            // ElevatedButton(
                            //   onPressed: () => _showAdzanNow('Subuh'),
                            //   child: const Text('Test Adzan Now'),
                            // ),
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
                        onChanged: (val) async {
                          setState(() {
                            data["aktif"] = val;
                          });
                          await _simpanStatus(data["nama"], val);
                          // reschedule when toggled
                          await _jadwalkanSemuaSholat();
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Switch(
                value: isOn,
                activeThumbColor: Colors.blue,
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
