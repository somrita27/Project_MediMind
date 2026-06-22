import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/schedule_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel (Android)
    const channel = AndroidNotificationChannel(
      'medicine_reminders',
      'Medicine Reminders',
      description: 'Reminders to take your medicines on time',
      importance: Importance.high,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — navigate to reminders screen
    // This is handled via go_router from main.dart
  }

  Future<void> scheduleRemindersForSchedule(
      MedicineSchedule schedule) async {
    int notifId = schedule.id.hashCode.abs() % 100000;

    for (final timing in schedule.timings) {
      final timeStr = schedule.timingTimes[timing] ?? '08:00 AM';

      var current = schedule.startDate;
      while (current.isBefore(schedule.endDate)) {
        final scheduledTime = _buildTZDateTime(current, timeStr);
        if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await _plugin.zonedSchedule(
            notifId++,
            '💊 Time for ${schedule.medicineName}',
            '${schedule.dosage} — ${schedule.instruction} ($timing)',
            scheduledTime,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'medicine_reminders',
                'Medicine Reminders',
                channelDescription:
                    'Reminders to take your medicines on time',
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
                color: const Color(0xFF2BAE7E),
                largeIcon: const DrawableResourceAndroidBitmap(
                    '@mipmap/ic_launcher'),
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
        current = current.add(const Duration(days: 1));
      }
    }
  }

  Future<void> cancelScheduleNotifications(String scheduleId) async {
    // Cancel by tag range — simplified approach
    final baseId = scheduleId.hashCode.abs() % 100000;
    for (int i = baseId; i < baseId + 500; i++) {
      await _plugin.cancel(i);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _buildTZDateTime(DateTime date, String timeStr) {
    final parts = timeStr.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (timeStr.contains('PM') && hour != 12) hour += 12;
    if (timeStr.contains('AM') && hour == 12) hour = 0;

    return tz.TZDateTime(
      tz.local,
      date.year, date.month, date.day,
      hour, minute,
    );
  }
}

// // ignore: avoid_classes_with_only_static_members
// class Color {
//   final int value;
//   const Color(this.value);
// }