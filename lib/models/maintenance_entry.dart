class MaintenanceEntry {
  const MaintenanceEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.title,
    required this.cost,
    required this.mileage,
    this.notes,
    this.nextMileage,
    this.nextDate,
    this.mileageAdvanceNotified = false,
    this.mileageDueNotified = false,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final String category;
  final String title;
  final double cost;
  final int mileage;
  final String? notes;
  final int? nextMileage;
  final DateTime? nextDate;

  // Merkt sich, ob die Vorwarnung für die kilometerabhängige
  // Wartung bereits angezeigt wurde.
  final bool mileageAdvanceNotified;

  // Merkt sich, ob die Fälligkeitswarnung für die kilometerabhängige
  // Wartung bereits angezeigt wurde.
  final bool mileageDueNotified;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'category': category,
      'title': title,
      'cost': cost,
      'mileage': mileage,
      'notes': notes,
      'next_mileage': nextMileage,
      'next_date': nextDate?.toIso8601String(),
      'mileage_advance_notified': mileageAdvanceNotified ? 1 : 0,
      'mileage_due_notified': mileageDueNotified ? 1 : 0,
    };
  }

  factory MaintenanceEntry.fromMap(Map<String, Object?> map) {
    return MaintenanceEntry(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      title: map['title'] as String,
      cost: (map['cost'] as num).toDouble(),
      mileage: map['mileage'] as int,
      notes: map['notes'] as String?,
      nextMileage: map['next_mileage'] as int?,
      nextDate: map['next_date'] == null
          ? null
          : DateTime.parse(map['next_date'] as String),
      mileageAdvanceNotified:
          (map['mileage_advance_notified'] as int? ?? 0) == 1,
      mileageDueNotified: (map['mileage_due_notified'] as int? ?? 0) == 1,
    );
  }

  MaintenanceEntry copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? category,
    String? title,
    double? cost,
    int? mileage,
    String? notes,
    int? nextMileage,
    DateTime? nextDate,
    bool? mileageAdvanceNotified,
    bool? mileageDueNotified,
  }) {
    return MaintenanceEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      category: category ?? this.category,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
      notes: notes ?? this.notes,
      nextMileage: nextMileage ?? this.nextMileage,
      nextDate: nextDate ?? this.nextDate,
      mileageAdvanceNotified:
          mileageAdvanceNotified ?? this.mileageAdvanceNotified,
      mileageDueNotified: mileageDueNotified ?? this.mileageDueNotified,
    );
  }
}
