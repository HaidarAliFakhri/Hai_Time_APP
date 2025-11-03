import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hai_time_app/main.dart';

class NotificationHelper {
  static Future<void> scheduleAdzanNotification({
    required String title,
    required String body,
    required DateTime prayerTime,
  }) async {
    final scheduledTime = prayerTime.subtract(const Duration(minutes: 10)); // ⏰ 10 menit sebelumnya

    await flutterLocalNotificationsPlugin.zonedSchedule(
      prayerTime.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adzan_channel',
          'Adzan Reminder',
          channelDescription: 'Pengingat waktu sholat',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('adzan'),
          playSound: true,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
