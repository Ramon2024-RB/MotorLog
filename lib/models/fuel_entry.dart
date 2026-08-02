class FuelEntry {
  const FuelEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.totalPrice,
    required this.isFullTank,
    this.station,
    this.notes,
  });

  final String id;
  final String vehicleId;
  final DateTime date;
  final int mileage;
  final double liters;
  final double pricePerLiter;
  final double totalPrice;
  final bool isFullTank;
  final String? station;
  final String? notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'liters': liters,
      'price_per_liter': pricePerLiter,
      'total_price': totalPrice,
      'is_full_tank': isFullTank ? 1 : 0,
      'station': station,
      'notes': notes,
    };
  }

  factory FuelEntry.fromMap(Map<String, Object?> map) {
    return FuelEntry(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      date: DateTime.parse(map['date'] as String),
      mileage: map['mileage'] as int,
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: (map['price_per_liter'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      isFullTank: (map['is_full_tank'] as int) == 1,
      station: map['station'] as String?,
      notes: map['notes'] as String?,
    );
  }
}