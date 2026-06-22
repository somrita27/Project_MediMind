import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/health_session_model.dart';
import '../models/schedule_model.dart';
import 'ai_service.dart';

class HealthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Sessions ──────────────────────────────────────────────

  Future<HealthSession> analyzeAndSave({
    required String userId,
    required String symptoms,
    File? imageFile,
    List<String> allergies = const [],
  }) async {
    String? imageUrl;

    // Upload image if provided
    if (imageFile != null) {
      final ref = _storage
          .ref()
          .child('symptom_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    // AI analysis
    final result = imageFile != null
        ? await AIService.analyzeSymptomsWithImage(
            symptoms: symptoms,
            imageFile: imageFile,
            allergies: allergies,
          )
        : await AIService.analyzeSymptoms(
            symptoms: symptoms,
            allergies: allergies,
          );

    // Save session to Firestore
    final docRef = await _db.collection('sessions').add({
      'userId': userId,
      'symptoms': symptoms,
      'imageUrl': imageUrl,
      'result': result.toMap(),
      'status': 'Completed',
      'createdAt': DateTime.now().toIso8601String(),
    });

    return HealthSession(
      id: docRef.id,
      userId: userId,
      symptoms: symptoms,
      imageUrl: imageUrl,
      result: result,
      status: 'Completed',
      createdAt: DateTime.now(),
    );
  }

  Future<List<HealthSession>> getUserSessions(String userId) async {
    final snap = await _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs
        .map((d) => HealthSession.fromMap(d.data(), d.id))
        .toList();
  }

  Future<HealthSession?> getSession(String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return HealthSession.fromMap(doc.data()!, doc.id);
  }

  // ── Schedules ─────────────────────────────────────────────

  Future<MedicineSchedule> saveSchedule({
    required String userId,
    required String sessionId,
    required String medicineName,
    required String dosage,
    required String instruction,
    required List<String> timings,
    required Map<String, String> timingTimes,
    required int durationDays,
  }) async {
    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: durationDays));

    final docRef = await _db.collection('schedules').add({
      'userId': userId,
      'sessionId': sessionId,
      'medicineName': medicineName,
      'dosage': dosage,
      'instruction': instruction,
      'timings': timings,
      'timingTimes': timingTimes,
      'durationDays': durationDays,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': true,
    });

    return MedicineSchedule(
      id: docRef.id,
      userId: userId,
      sessionId: sessionId,
      medicineName: medicineName,
      dosage: dosage,
      instruction: instruction,
      timings: timings,
      timingTimes: timingTimes,
      durationDays: durationDays,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );
  }

  Future<List<MedicineSchedule>> getUserSchedules(String userId) async {
    final snap = await _db
        .collection('schedules')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snap.docs
        .map((d) => MedicineSchedule.fromMap(d.data(), d.id))
        .toList();
  }

  // ── Reminders ─────────────────────────────────────────────

  Future<List<ReminderModel>> getTodayReminders(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('scheduledAt', isLessThan: endOfDay.toIso8601String())
        .orderBy('scheduledAt')
        .get();

    return snap.docs
        .map((d) => ReminderModel.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> updateReminderStatus(String reminderId, String status) async {
    await _db.collection('reminders').doc(reminderId).update({'status': status});
  }

  /// Generate reminder documents for a schedule (called after saving schedule)
  Future<void> generateReminders(MedicineSchedule schedule) async {
    final batch = _db.batch();
    var current = schedule.startDate;

    while (current.isBefore(schedule.endDate)) {
      for (final timing in schedule.timings) {
        final timeStr = schedule.timingTimes[timing] ?? '08:00 AM';
        final timeParts = _parseTime(timeStr);
        final scheduledAt = DateTime(
          current.year, current.month, current.day,
          timeParts[0], timeParts[1],
        );

        final ref = _db.collection('reminders').doc();
        batch.set(ref, {
          'userId': schedule.userId,
          'scheduleId': schedule.id,
          'medicineName': schedule.medicineName,
          'dosage': schedule.dosage,
          'instruction': schedule.instruction,
          'timing': timing,
          'time': timeStr,
          'scheduledAt': scheduledAt.toIso8601String(),
          'status': 'Upcoming',
        });
      }
      current = current.add(const Duration(days: 1));
    }

    await batch.commit();
  }

  List<int> _parseTime(String timeStr) {
    // "08:00 AM" -> [8, 0]
    final parts = timeStr.replaceAll(' AM', '').replaceAll(' PM', '').split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (timeStr.contains('PM') && hour != 12) hour += 12;
    if (timeStr.contains('AM') && hour == 12) hour = 0;
    return [hour, minute];
  }
}