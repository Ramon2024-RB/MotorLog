class Maintenance {
  const Maintenance({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.category,
    required this.date,
    required this.mileage,
    required this.cost,
    this.workshop,
    this.notes,
    this.nextMileage,
    this.nextDate,
  });

  final String id;
  final String vehicleId;

  final String title;
  final String category;

  final DateTime date;

  final int mileage;

  final double cost;

  final String? workshop;
  final String? notes;

  final int? nextMileage;
  final DateTime? nextDate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'cost': cost,
      'workshop': workshop,
      'notes': notes,
      'nextMileage': nextMileage,
      'nextDate': nextDate?.toIso8601String(),
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'],
      vehicleId: map['vehicleId'],
      title: map['title'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      mileage: map['mileage'],
      cost: (map['cost'] as num).toDouble(),
      workshop: map['workshop'],
      notes: map['notes'],
      nextMileage: map['nextMileage'],
      nextDate: map['nextDate'] == null
          ? null
          : DateTime.parse(map['nextDate']),
    );
  }
}
