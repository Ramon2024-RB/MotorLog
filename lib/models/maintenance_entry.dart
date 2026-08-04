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
    );
  }
}
