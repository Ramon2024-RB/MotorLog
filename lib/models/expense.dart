class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.amount,
    required this.title,
    this.mileage,
    this.notes,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final String category;
  final double amount;
  final String title;
  final int? mileage;
  final String? notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'title': title,
      'mileage': mileage,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      title: map['title'] as String,
      mileage: map['mileage'] as int?,
      notes: map['notes'] as String?,
    );
  }
}