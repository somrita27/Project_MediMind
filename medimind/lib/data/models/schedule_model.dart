class MedicineSchedule {
  final String id;
  final String userId;
  final String sessionId;
  final String medicineName;
  final String dosage;
  final String instruction;
  final List<String> timings; // ['Morning', 'Afternoon', 'Night']
  final Map<String, String> timingTimes; // {'Morning': '08:00 AM', ...}
  final int durationDays;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  MedicineSchedule({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.medicineName,
    required this.dosage,
    required this.instruction,
    required this.timings,
    required this.timingTimes,
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory MedicineSchedule.fromMap(Map<String, dynamic> map, String docId) {
    return MedicineSchedule(
      id: docId,
      userId: map['userId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      instruction: map['instruction'] ?? '',
      timings: List<String>.from(map['timings'] ?? []),
      timingTimes: Map<String, String>.from(map['timingTimes'] ?? {}),
      durationDays: map['durationDays'] ?? 1,
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
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
    'isActive': isActive,
  };
}

class ReminderModel {
  final String id;
  final String userId;
  final String scheduleId;
  final String medicineName;
  final String dosage;
  final String instruction;
  final String timing; // 'Morning' | 'Afternoon' | 'Night'
  final String time;   // '08:00 AM'
  final DateTime scheduledAt;
  final String status; // 'Upcoming' | 'Taken' | 'Missed'

  ReminderModel({
    required this.id,
    required this.userId,
    required this.scheduleId,
    required this.medicineName,
    required this.dosage,
    required this.instruction,
    required this.timing,
    required this.time,
    required this.scheduledAt,
    required this.status,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReminderModel(
      id: docId,
      userId: map['userId'] ?? '',
      scheduleId: map['scheduleId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      instruction: map['instruction'] ?? '',
      timing: map['timing'] ?? '',
      time: map['time'] ?? '',
      scheduledAt: DateTime.parse(map['scheduledAt']),
      status: map['status'] ?? 'Upcoming',
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'scheduleId': scheduleId,
    'medicineName': medicineName,
    'dosage': dosage,
    'instruction': instruction,
    'timing': timing,
    'time': time,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status,
  };

  ReminderModel copyWith({String? status}) => ReminderModel(
    id: id, userId: userId, scheduleId: scheduleId,
    medicineName: medicineName, dosage: dosage, instruction: instruction,
    timing: timing, time: time, scheduledAt: scheduledAt,
    status: status ?? this.status,
  );
}