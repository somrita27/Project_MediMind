class MedicineModel {
  final String name;
  final String dosage;
  final String instruction;
  final String timeOfDay; // morning / afternoon / night
  final String? notes;

  MedicineModel({
    required this.name,
    required this.dosage,
    required this.instruction,
    required this.timeOfDay,
    this.notes,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      instruction: map['instruction'] ?? '',
      timeOfDay: map['timeOfDay'] ?? 'morning',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'dosage': dosage,
    'instruction': instruction,
    'timeOfDay': timeOfDay,
    'notes': notes,
  };
}

class AnalysisResult {
  final String likelyCondition;
  final double confidence;
  final List<MedicineModel> medicines;
  final List<String> generalAdvice;
  final String? disclaimer;

  AnalysisResult({
    required this.likelyCondition,
    required this.confidence,
    required this.medicines,
    required this.generalAdvice,
    this.disclaimer,
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> map) {
  // If data comes from FastAPI
  if (map.containsKey('disease')) {
    final medicineName = map['medicine'] ?? '';

    final medicines = [
      MedicineModel(
        name: medicineName,
        dosage: map['frequency'] ?? '',
        instruction: map['duration']?['label'] ?? '',
        timeOfDay: (map['schedule'] != null &&
                (map['schedule'] as List).isNotEmpty)
            ? map['schedule'][0]['label'].toString().toLowerCase()
            : 'morning',
        notes: map['precautions'] ?? '',
      )
    ];

    return AnalysisResult(
      likelyCondition: map['disease'] ?? '',
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      medicines: medicines,
      generalAdvice: [
        map['precautions'] ?? '',
      ],
      disclaimer: map['disclaimer'],
    );
  }

  // Old Claude format
  return AnalysisResult(
    likelyCondition: map['likelyCondition'] ?? '',
    confidence: (map['confidence'] ?? 0.0).toDouble(),
    medicines: (map['medicines'] as List? ?? [])
        .map((m) => MedicineModel.fromMap(m))
        .toList(),
    generalAdvice: List<String>.from(map['generalAdvice'] ?? []),
    disclaimer: map['disclaimer'],
  );
}

  Map<String, dynamic> toMap() => {
    'likelyCondition': likelyCondition,
    'confidence': confidence,
    'medicines': medicines.map((m) => m.toMap()).toList(),
    'generalAdvice': generalAdvice,
    'disclaimer': disclaimer,
  };
}

class HealthSession {
  final String id;
  final String userId;
  final String symptoms;
  final String? imageUrl;
  final AnalysisResult result;
  final String status; // Completed / Active
  final DateTime createdAt;

  HealthSession({
    required this.id,
    required this.userId,
    required this.symptoms,
    this.imageUrl,
    required this.result,
    required this.status,
    required this.createdAt,
  });

  factory HealthSession.fromMap(Map<String, dynamic> map, String docId) {
    return HealthSession(
      id: docId,
      userId: map['userId'] ?? '',
      symptoms: map['symptoms'] ?? '',
      imageUrl: map['imageUrl'],
      result: AnalysisResult.fromMap(map['result'] ?? {}),
      status: map['status'] ?? 'Completed',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'symptoms': symptoms,
    'imageUrl': imageUrl,
    'result': result.toMap(),
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}