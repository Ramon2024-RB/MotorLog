class MaintenanceWork {
  const MaintenanceWork({
    required this.id,
    required this.maintenanceEntryId,
    required this.type,
    this.customName,
    this.nextMileage,
    this.nextDate,
    this.mileageAdvanceNotified = false,
    this.mileageDueNotified = false,
  });

  final String id;

  final String maintenanceEntryId;

  /// Stabiler technischer Schlüssel der durchgeführten Arbeit.
  ///
  /// Beispiele:
  /// oil_change
  /// oil_filter
  /// brake_pads_front
  /// brake_discs_front
  /// custom
  final String type;

  /// Frei vergebener Name bei einer eigenen Arbeit.
  ///
  /// Wird nur verwendet, wenn [type] == 'custom'.
  ///
  /// Beispiel:
  /// Kupplung erneuert
  final String? customName;

  /// Optionaler Kilometerstand, bei dem genau diese Arbeit
  /// erneut fällig wird.
  final int? nextMileage;

  /// Optionales Datum, an dem genau diese Arbeit erneut
  /// fällig wird.
  final DateTime? nextDate;

  final bool mileageAdvanceNotified;

  final bool mileageDueNotified;

  bool get isCustom => type == 'custom';

  String get displayName {
    if (isCustom) {
      final name = customName?.trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }

      return 'Eigene Arbeit';
    }

    return type;
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'maintenance_entry_id': maintenanceEntryId,
      'type': type,
      'custom_name': customName,
      'next_mileage': nextMileage,
      'next_date': nextDate?.toIso8601String(),
      'mileage_advance_notified': mileageAdvanceNotified ? 1 : 0,
      'mileage_due_notified': mileageDueNotified ? 1 : 0,
    };
  }

  factory MaintenanceWork.fromMap(Map<String, Object?> map) {
    return MaintenanceWork(
      id: map['id'] as String,
      maintenanceEntryId: map['maintenance_entry_id'] as String,
      type: map['type'] as String,
      customName: map['custom_name'] as String?,
      nextMileage: map['next_mileage'] as int?,
      nextDate: map['next_date'] == null
          ? null
          : DateTime.parse(map['next_date'] as String),
      mileageAdvanceNotified:
          (map['mileage_advance_notified'] as int? ?? 0) == 1,
      mileageDueNotified: (map['mileage_due_notified'] as int? ?? 0) == 1,
    );
  }

  MaintenanceWork copyWith({
    String? id,
    String? maintenanceEntryId,
    String? type,
    String? customName,
    int? nextMileage,
    DateTime? nextDate,
    bool? mileageAdvanceNotified,
    bool? mileageDueNotified,
  }) {
    return MaintenanceWork(
      id: id ?? this.id,
      maintenanceEntryId: maintenanceEntryId ?? this.maintenanceEntryId,
      type: type ?? this.type,
      customName: customName ?? this.customName,
      nextMileage: nextMileage ?? this.nextMileage,
      nextDate: nextDate ?? this.nextDate,
      mileageAdvanceNotified:
          mileageAdvanceNotified ?? this.mileageAdvanceNotified,
      mileageDueNotified: mileageDueNotified ?? this.mileageDueNotified,
    );
  }
}
