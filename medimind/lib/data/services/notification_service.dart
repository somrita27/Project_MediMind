import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../models/schedule_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
      importance: Importance.max,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // If the app was launched by tapping a notification (e.g. from a
    // terminated state), surface the alarm screen right away.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final response = launchDetails!.notificationResponse;
      if (response != null) _onNotificationTap(response);
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      // Push the full-screen alarm UI so tapping the reminder always shows
      // the "time to take your medicine" screen, not just the reminders list.
      router.push(AppRoutes.medicineAlarm, extra: data);
    } catch (_) {
      // Malformed payload — fall back to the reminders list.
      router.go(AppRoutes.reminders);
    }
  }

  String _payloadFor({
    required String reminderId,
    required String medicineName,
    required String dosage,
    required String instruction,
    required String time,
  }) {
    return jsonEncode({
      'reminderId': reminderId,
      'medicineName': medicineName,
      'dosage': dosage,
      'instruction': instruction,
      'time': time,
    });
  }

  NotificationDetails _alarmStyleDetails({
    required String title,
    required String medicineName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Reminders to take your medicines on time',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF2BAE7E),
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        // Wakes the screen and shows a full-screen alarm-style UI even
        // when the phone is locked, like a real alarm clock.
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Schedules a local (alarm-style) notification for each reminder doc,
  /// so tapping one always maps back to the exact Firestore reminder that
  /// should be marked taken/missed.
  Future<void> scheduleRemindersForReminders(
      List<ReminderModel> reminders) async {
    for (final reminder in reminders) {
      final scheduledTime = tz.TZDateTime.from(reminder.scheduledAt, tz.local);
      if (!scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) continue;

      final notifId = reminder.id.hashCode.abs() % 100000;
      await _plugin.zonedSchedule(
        notifId,
        '💊 Time for ${reminder.medicineName}',
        '${reminder.dosage} — ${reminder.instruction} (${reminder.timing})',
        scheduledTime,
        _alarmStyleDetails(
          title: '💊 Time for ${reminder.medicineName}',
          medicineName: reminder.medicineName,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: _payloadFor(
          reminderId: reminder.id,
          medicineName: reminder.medicineName,
          dosage: reminder.dosage,
          instruction: reminder.instruction,
          time: reminder.time,
        ),
      );
    }
  }

  Future<void> scheduleRemindersForSchedule(MedicineSchedule schedule) async {
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
            _alarmStyleDetails(
              title: '💊 Time for ${schedule.medicineName}',
              medicineName: schedule.medicineName,
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: _payloadFor(
              reminderId: schedule.id,
              medicineName: schedule.medicineName,
              dosage: schedule.dosage,
              instruction: schedule.instruction,
              time: timeStr,
            ),
          );
        }
        current = current.add(const Duration(days: 1));
      }
    }
  }

  /// Schedules a single one-off reminder a given duration from now — used
  /// for the "Snooze 10 mins" action on the alarm screen.
  Future<void> scheduleOneOffReminder({
    required String reminderId,
    required String medicineName,
    required String dosage,
    required String instruction,
    required String time,
    required Duration after,
  }) async {
    final notifId = (reminderId.hashCode.abs() % 100000) + 900000;
    final scheduledTime = tz.TZDateTime.now(tz.local).add(after);

    await _plugin.zonedSchedule(
      notifId,
      '💊 Time for $medicineName',
      '$dosage — $instruction',
      scheduledTime,
      _alarmStyleDetails(
        title: '💊 Time for $medicineName',
        medicineName: medicineName,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: _payloadFor(
        reminderId: reminderId,
        medicineName: medicineName,
        dosage: dosage,
        instruction: instruction,
        time: time,
      ),
    );
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
    final parts =
        timeStr.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (timeStr.contains('PM') && hour != 12) hour += 12;
    if (timeStr.contains('AM') && hour == 12) hour = 0;

    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }
}
