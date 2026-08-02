class Vehicle {
  const Vehicle({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.mileage,
    required this.vehicleType,
    this.licensePlate,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final int mileage;
  final String vehicleType;
  final String? licensePlate;
  final bool isDefault;

  Vehicle copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    int? year,
    String? fuelType,
    int? mileage,
    String? vehicleType,
    String? licensePlate,
    bool? isDefault,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      mileage: mileage ?? this.mileage,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'mileage': mileage,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'is_default': isDefault ? 1 : 0,
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
      vehicleType: (map['vehicle_type'] as String?) ?? 'Auto',
      licensePlate: map['license_plate'] as String?,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}