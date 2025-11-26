import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service notifikasi lokal (flutter_local_notifications)
class NotifikasiService {
  static final FlutterLocalNotificationsPlugin notif =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await notif.initialize(settings);
  }

  // Generate id aman 32-bit signed (0 .. 2147483646)
  static int generateSafeNotifId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    // mod by 2^31-1 to ensure fits 32-bit signed int
    return (ms % 2147483647).toInt();
  }

  // Low-level schedule (may throw) — same as before
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    await notif.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kegiatan_channel',
          'Pengingat Kegiatan',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Low-level cancel
  static Future<void> cancel(int id) async {
    await notif.cancel(id);
  }

  // ==== SAFE WRAPPERS ====
  // gunakan ini dalam logic utama agar schedule/cancel gagal tidak memblokir penyimpanan
  static Future<void> safeSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    try {
      // Jangan schedule di masa lalu
      if (date.isBefore(DateTime.now())) return;
      await schedule(id: id, title: title, body: body, date: date);
    } catch (e) {
      // Log error tapi jangan lempar lagi agar UI/simpan tetap sukses
      // print atau debugPrint sesuai kebutuhan
      debugPrint("Notifikasi gagal dijadwalkan: $e");
    }
  }

  static Future<void> safeCancel(int id) async {
    try {
      await cancel(id);
    } catch (e) {
      debugPrint("Gagal cancel notifikasi id=$id: $e");
    }
  }
}
