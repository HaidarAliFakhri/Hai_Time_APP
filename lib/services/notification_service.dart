// services/notification_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point') // penting supaya Flutter tidak tree-shake fungsi ini
void notificationTapBackground(NotificationResponse response) {
  // minimal: jangan panggil context UI di sini.
  // simpan payload/log atau hanya debugPrint
  try {
    final payload = response.payload;
    debugPrint('Background notification tapped. payload: $payload');
    // jika mau lakukan logic non-UI, lakukan di sini (synchronous/simple)
  } catch (e) {
    debugPrint('Error in background notification handler: $e');
  }
}

/// Notifikasi lokal menggunakan flutter_local_notifications + timezone
class NotifikasiService {
  static final FlutterLocalNotificationsPlugin notif =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'kegiatan_channel';
  static const String _channelName = 'Pengingat Kegiatan';
  static const String _channelDescription = 'Channel untuk pengingat kegiatan';

  /// init harus dipanggil sekali dari main() sebelum schedule
  static Future<void> init({void Function(String? payload)? onTap}) async {
    // timezone safe init
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    // Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init (Darwin style settings) — safe untuk banyak versi
    final iosInit = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        debugPrint('iOS legacy local notification: $id (payload:$payload)');
      },
    );

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    // initialize with tap handlers
    await notif.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        try {
          final String? payload = response.payload;
          if (onTap != null) onTap(payload);
        } catch (e) {
          debugPrint("Error handling notification tap: $e");
        }
      },
      // kirim top-level handler (jangan gunakan closure di sini)
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android channel (Android 8+)
    if (Platform.isAndroid) {
      final androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      final androidPlugin = notif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        try {
          await androidPlugin.createNotificationChannel(androidChannel);
        } catch (e) {
          debugPrint('Gagal membuat channel Android: $e');
        }
      }

      // Request runtime permission for Android 13+ (POST_NOTIFICATIONS)
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('Gagal request permission notification (Android): $e');
      }
    }

    // Request permissions on iOS — use dynamic resolution to avoid typing issues
    if (Platform.isIOS) {
      try {
        // resolvePlatformSpecificImplementation without concrete type parameter
        // returns platform impl or null. We call requestPermissions dynamically.
        final dynamic iosImpl = notif.resolvePlatformSpecificImplementation();
        if (iosImpl != null) {
          // many platform impls (Darwin plugin) expose requestPermissions({alert,badge,sound})
          try {
            await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
          } catch (e) {
            // fallback: some older impls use different method signature — ignore
            debugPrint('iOS impl resolved but requestPermissions failed: $e');
          }
        } else {
          debugPrint('iOS platform-specific impl not available (null)');
        }
      } catch (e) {
        debugPrint('iOS permission request failed: $e');
      }
    }
  }

  /// Generate id aman 32-bit signed
  static int generateSafeNotifId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return (ms % 2147483647).toInt();
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    String? payload,
  }) async {
    try {
      // ensure tz
      try {
        tz.initializeTimeZones();
      } catch (_) {}

      final tzDate = tz.TZDateTime.from(date, tz.local);

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        ticker: 'Pengingat Kegiatan',
      );

      final iosDetails = DarwinNotificationDetails();

      final platform = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await notif.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        platform,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('schedule error: $e');
      rethrow;
    }
  }

  static Future<void> cancel(int id) async {
    await notif.cancel(id);
  }

  static Future<void> cancelAll() async {
    await notif.cancelAll();
  }

  static Future<List<int>> pendingNotificationIds() async {
    final pending = await notif.pendingNotificationRequests();
    return pending.map((p) => p.id).toList();
  }

  // SAFE WRAPPERS
  static Future<void> safeSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    String? payload,
  }) async {
    try {
      if (date.isBefore(DateTime.now())) return;
      await schedule(
        id: id,
        title: title,
        body: body,
        date: date,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Notifikasi gagal dijadwalkan (safe): $e");
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
