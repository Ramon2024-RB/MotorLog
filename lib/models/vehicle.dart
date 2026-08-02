class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.mileage,
    this.licensePlate,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final int mileage;
  final String? licensePlate;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'mileage': mileage,
      'license_plate': licensePlate,
    };
  }

  factory Vehicle.fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id'] as String,
      name: map['name'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      fuelType: map['fuel_type'] as String,
      mileage: map['mileage'] as int,
      licensePlate: map['license_plate'] as String?,
    );
  }
}