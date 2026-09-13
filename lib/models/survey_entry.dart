/// Condition options for a facility inspection.
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

/// A single field-survey record. Stored locally in Hive (IndexedDB on web)
/// so the form keeps working with zero network connectivity.
class SurveyEntry {
  final String id;
  final String facilityName;
  final String location;
  final FacilityCondition condition;
  final String notes;
  final String? photoBase64;
  final DateTime createdAt;
  final bool synced;

  const SurveyEntry({
    required this.id,
    required this.facilityName,
    required this.location,
    required this.condition,
    required this.notes,
    required this.createdAt,
    this.photoBase64,
    this.synced = false,
  });

  SurveyEntry copyWith({bool? synced}) {
    return SurveyEntry(
      id: id,
      facilityName: facilityName,
      location: location,
      condition: condition,
      notes: notes,
      createdAt: createdAt,
      photoBase64: photoBase64,
      synced: synced ?? this.synced,
    );
  }

  /// Hive (through hive_flutter) stores plain maps here, avoiding the need
  /// for generated TypeAdapters — keeps the mini-project build simple.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facilityName': facilityName,
      'location': location,
      'condition': condition.name,
      'notes': notes,
      'photoBase64': photoBase64,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory SurveyEntry.fromMap(Map<dynamic, dynamic> map) {
    return SurveyEntry(
      id: map['id'] as String,
      facilityName: map['facilityName'] as String,
      location: map['location'] as String,
      condition: FacilityConditionLabel.fromName(map['condition'] as String),
      notes: map['notes'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      synced: map['synced'] as bool? ?? false,
    );
  }
}
