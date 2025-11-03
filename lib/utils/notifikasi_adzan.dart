import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hai_time_app/main.dart'; // biar bisa akses plugin

Future<void> jadwalkanAdzan(
  String namaSholat,
  DateTime waktu,
) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    waktu.hashCode, // id unik
    'Waktu Sholat $namaSholat',
    'Sudah masuk waktu $namaSholat, ayo sholat!',
    tz.TZDateTime.from(waktu, tz.local),
    NotificationDetails(
      android: AndroidNotificationDetails(
        'adzan_channel',
        'Pengingat Sholat',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adzan'), // tanpa .mp3
        playSound: true,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
