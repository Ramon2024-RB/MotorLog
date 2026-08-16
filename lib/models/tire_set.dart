class TireSet {
  const TireSet({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.tireType,
    required this.width,
    required this.aspectRatio,
    required this.rimDiameter,
    required this.isMounted,
    this.manufacturer,
    this.model,
    this.purchaseDate,
    this.purchasePrice,
    this.productionYear,
    this.treadDepth,
    this.mountedMileage,
    this.mountedDate,
    this.totalMileage = 0,
    this.notes,
  });

  final String id;
  final String vehicleId;

  /// Eigener Name des Reifensatzes,
  /// zum Beispiel "Winterreifen 2026".
  final String name;

  /// Sommerreifen, Winterreifen oder Ganzjahresreifen.
  final String tireType;

  /// Reifenbreite, zum Beispiel 215.
  final int width;

  /// Querschnitt, zum Beispiel 65.
  final int aspectRatio;

  /// Felgendurchmesser in Zoll, zum Beispiel 16.
  final int rimDiameter;

  final String? manufacturer;
  final String? model;

  final DateTime? purchaseDate;
  final double? purchasePrice;

  /// Produktionsjahr des Reifens.
  final int? productionYear;

  /// Profiltiefe in Millimetern.
  final double? treadDepth;

  /// Gibt an, ob dieser Reifensatz aktuell montiert ist.
  final bool isMounted;

  /// Kilometerstand bei der letzten Montage dieses Reifensatzes.
  ///
  /// Dieser Wert wird benötigt, um beim nächsten Reifenwechsel
  /// zu berechnen, wie viele Kilometer mit diesem Reifensatz
  /// gefahren wurden.
  final int? mountedMileage;

  /// Datum der letzten Montage dieses Reifensatzes.
  final DateTime? mountedDate;

  /// Gesamte bisher mit diesem Reifensatz gefahrene Strecke.
  ///
  /// Beispiel:
  /// Sommerreifen:
  /// 99.000 -> 107.000 km = 8.000 km
  ///
  /// Später erneut montiert:
  /// 112.000 -> 118.000 km = 6.000 km
  ///
  /// totalMileage = 14.000 km
  final int totalMileage;

  final String? notes;

  String get tireSize {
    return '$width/$aspectRatio R$rimDiameter';
  }

  TireSet copyWith({
    String? id,
    String? vehicleId,
    String? name,
    String? tireType,
    int? width,
    int? aspectRatio,
    int? rimDiameter,
    String? manufacturer,
    String? model,
    DateTime? purchaseDate,
    double? purchasePrice,
    int? productionYear,
    double? treadDepth,
    bool? isMounted,
    int? mountedMileage,
    DateTime? mountedDate,
    int? totalMileage,
    String? notes,
  }) {
    return TireSet(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      tireType: tireType ?? this.tireType,
      width: width ?? this.width,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      rimDiameter: rimDiameter ?? this.rimDiameter,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      productionYear: productionYear ?? this.productionYear,
      treadDepth: treadDepth ?? this.treadDepth,
      isMounted: isMounted ?? this.isMounted,
      mountedMileage: mountedMileage ?? this.mountedMileage,
      mountedDate: mountedDate ?? this.mountedDate,
      totalMileage: totalMileage ?? this.totalMileage,
      notes: notes ?? this.notes,
    );
  }

  factory TireSet.fromMap(Map<String, dynamic> map) {
    return TireSet(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      name: map['name'] as String,
      tireType: map['tire_type'] as String,
      width: map['width'] as int,
      aspectRatio: map['aspect_ratio'] as int,
      rimDiameter: map['rim_diameter'] as int,
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      purchaseDate: map['purchase_date'] == null
          ? null
          : DateTime.parse(map['purchase_date'] as String),
      purchasePrice: map['purchase_price'] == null
          ? null
          : (map['purchase_price'] as num).toDouble(),
      productionYear: map['production_year'] as int?,
      treadDepth: map['tread_depth'] == null
          ? null
          : (map['tread_depth'] as num).toDouble(),
      isMounted: (map['is_mounted'] as int) == 1,
      mountedMileage: map['mounted_mileage'] as int?,
      mountedDate: map['mounted_date'] == null
          ? null
          : DateTime.parse(map['mounted_date'] as String),
      totalMileage: map['total_mileage'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'name': name,
      'tire_type': tireType,
      'width': width,
      'aspect_ratio': aspectRatio,
      'rim_diameter': rimDiameter,
      'manufacturer': manufacturer,
      'model': model,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'production_year': productionYear,
      'tread_depth': treadDepth,
      'is_mounted': isMounted ? 1 : 0,
      'mounted_mileage': mountedMileage,
      'mounted_date': mountedDate?.toIso8601String(),
      'total_mileage': totalMileage,
      'notes': notes,
    };
  }
}
