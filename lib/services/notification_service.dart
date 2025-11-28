// lib/services/notification_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse response) {
  try {
    debugPrint('Background notification tapped: ${response.payload}');
  } catch (e, st) {
    debugPrint('Error in background handler: $e\n$st');
  }
}

class NotifikasiService {
  NotifikasiService._();

  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'kegiatan_channel_v1';
  static const String _channelName = 'Pengingat Kegiatan';
  static const String _channelDescription = 'Channel untuk pengingat kegiatan';

  static Future<void> init({void Function(String? payload)? onTap}) async {
    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _notif.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        try {
          final payload = response.payload;
          if (onTap != null) onTap(payload);
        } catch (e, st) {
          debugPrint('Error handling tap: $e\n$st');
        }
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImpl = _notif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        final channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
        );
        try {
          await androidImpl.createNotificationChannel(channel);
          debugPrint('Notification channel created/verified: $_channelId');
        } catch (e, st) {
          debugPrint('Failed creating channel: $e\n$st');
        }
      }
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e, st) {
        debugPrint('Permission.request error (android): $e\n$st');
      }
    }

    if (Platform.isIOS) {
      try {
        final iosImpl = _notif
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImpl != null) {
          await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } catch (e, st) {
        debugPrint('iOS requestPermissions failed: $e\n$st');
      }
    }
  }

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
    String? soundResource,
  }) async {
    try {
      try {
        tz.initializeTimeZones();
      } catch (_) {}

      final tzDate = tz.TZDateTime.from(date, tz.local);

      AndroidNotificationDetails androidDetails;
      if (soundResource != null && soundResource.isNotEmpty) {
        androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundResource),
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
        );
      }

      DarwinNotificationDetails iosDetails;
      if (soundResource != null && soundResource.isNotEmpty) {
        iosDetails = DarwinNotificationDetails(
          sound: '$soundResource.aiff',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
      } else {
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
      }

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notif.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        platformDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled notif id=$id at $tzDate payload=$payload');
    } catch (e, st) {
      debugPrint('schedule error: $e\n$st');
      rethrow;
    }
  }

  static Future<void> safeSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    String? payload,
    String? soundResource,
  }) async {
    try {
      if (date.isBefore(DateTime.now())) {
        debugPrint('safeSchedule: date is in the past, skipping id=$id');
        return;
      }
      await schedule(
        id: id,
        title: title,
        body: body,
        date: date,
        payload: payload,
        soundResource: soundResource,
      );
    } catch (e, st) {
      debugPrint('safeSchedule failed: $e\n$st');
    }
  }

  /// cancel wrapper (safe)
  static Future<void> safeCancel(int id) async {
    try {
      await _notif.cancel(id);
      debugPrint('safeCancel: cancelled id=$id');
    } catch (e, st) {
      debugPrint('safeCancel failed for id=$id : $e\n$st');
    }
  }

  /// Attempt to cancel when you might have a String or null that could be parseable to int.
  /// Useful when old code stored string IDs or you tried canceling using docId accidentally.
  static Future<void> safeCancelMaybe(String? maybeId) async {
    if (maybeId == null) return;
    final raw = int.tryParse(maybeId);
    if (raw != null) {
      await safeCancel(raw);
      // also try mapped 32-bit safe variant (defensive)
      final mapped = (raw % 2147483647).toInt();
      if (mapped != raw) await safeCancel(mapped);
    } else {
      debugPrint('safeCancelMaybe: could not parse "$maybeId" to int');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _notif.cancel(id);
      debugPrint('Cancelled notif id=$id');
    } catch (e, st) {
      debugPrint('cancel failed: $e\n$st');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _notif.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e, st) {
      debugPrint('cancelAll failed: $e\n$st');
    }
  }

  static Future<List<int>> pendingNotificationIds() async {
    try {
      final pending = await _notif.pendingNotificationRequests();
      return pending.map((p) => p.id).toList();
    } catch (e, st) {
      debugPrint('pendingNotificationIds failed: $e\n$st');
      return [];
    }
  }
}
