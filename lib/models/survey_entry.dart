enum FacilityCondition { good, needsRepair, damaged }

extension FacilityConditionLabel on FacilityCondition {
  String get label {
    switch (this) {
      case FacilityCondition.good:
        return 'Tốt';
      case FacilityCondition.needsRepair:
        return 'Cần sửa chữa';
      case FacilityCondition.damaged:
        return 'Hư hỏng';
    }
  }

  static FacilityCondition fromName(String name) {
    return FacilityCondition.values.firstWhere(
      (e) => e.name == name,
      orElse: () => FacilityCondition.good,
    );
  }
}

class SurveyEntry {
  final String id;
  final String inspectorName; // Thêm tên người khảo sát
  final String facilityName;
  final String location;
  final FacilityCondition condition;
  final String notes;
  final String? photoBase64;
  final DateTime createdAt;
  final bool synced;
  final int cleanlinessRating;
  final int safetyRating;
  final int usabilityRating;

  const SurveyEntry({
    required this.id,
    required this.inspectorName,
    required this.facilityName,
    required this.location,
    required this.condition,
    required this.notes,
    required this.createdAt,
    this.photoBase64,
    this.synced = false,
    this.cleanlinessRating = 5,
    this.safetyRating = 5,
    this.usabilityRating = 5,
  });

  SurveyEntry copyWith({bool? synced}) {
    return SurveyEntry(
      id: id,
      inspectorName: inspectorName,
      facilityName: facilityName,
      location: location,
      condition: condition,
      notes: notes,
      createdAt: createdAt,
      photoBase64: photoBase64,
      synced: synced ?? this.synced,
      cleanlinessRating: cleanlinessRating,
      safetyRating: safetyRating,
      usabilityRating: usabilityRating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectorName': inspectorName,
      'facilityName': facilityName,
      'location': location,
      'condition': condition.name,
      'notes': notes,
      'photoBase64': photoBase64,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
      'cleanlinessRating': cleanlinessRating,
      'safetyRating': safetyRating,
      'usabilityRating': usabilityRating,
    };
  }

  factory SurveyEntry.fromMap(Map<dynamic, dynamic> map) {
    return SurveyEntry(
      id: map['id'] as String,
      inspectorName: map['inspectorName'] as String? ?? 'Chưa rõ',
      facilityName: map['facilityName'] as String,
      location: map['location'] as String,
      condition: FacilityConditionLabel.fromName(map['condition'] as String),
      notes: map['notes'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      synced: map['synced'] as bool? ?? false,
      cleanlinessRating: map['cleanlinessRating'] as int? ?? 5,
      safetyRating: map['safetyRating'] as int? ?? 5,
      usabilityRating: map['usabilityRating'] as int? ?? 5,
    );
  }
}
