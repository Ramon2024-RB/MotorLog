class TireMountHistory {
  const TireMountHistory({
    required this.id,
    required this.vehicleId,
    required this.tireSetId,
    required this.mountedDate,
    required this.mountedMileage,
    this.unmountedDate,
    this.unmountedMileage,
  });

  final String id;
  final String vehicleId;
  final String tireSetId;

  /// Datum, an dem der Reifensatz montiert wurde.
  final DateTime mountedDate;

  /// Kilometerstand bei der Montage.
  final int mountedMileage;

  /// Datum der Demontage.
  ///
  /// Ist null, solange der Reifensatz aktuell montiert ist.
  final DateTime? unmountedDate;

  /// Kilometerstand bei der Demontage.
  ///
  /// Ist null, solange der Reifensatz aktuell montiert ist.
  final int? unmountedMileage;

  /// Gibt an, ob dieser Eintrag eine aktuell laufende Montage darstellt.
  bool get isActive {
    return unmountedDate == null && unmountedMileage == null;
  }

  /// Kilometer, die während dieser abgeschlossenen Montage
  /// mit dem Reifensatz gefahren wurden.
  ///
  /// Bei einer noch laufenden Montage ist der Wert null,
  /// da dafür der aktuelle Fahrzeugkilometerstand benötigt wird.
  int? get completedDistance {
    final endMileage = unmountedMileage;

    if (endMileage == null) {
      return null;
    }

    final distance = endMileage - mountedMileage;

    if (distance < 0) {
      return 0;
    }

    return distance;
  }

  TireMountHistory copyWith({
    String? id,
    String? vehicleId,
    String? tireSetId,
    DateTime? mountedDate,
    int? mountedMileage,
    DateTime? unmountedDate,
    int? unmountedMileage,
  }) {
    return TireMountHistory(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      tireSetId: tireSetId ?? this.tireSetId,
      mountedDate: mountedDate ?? this.mountedDate,
      mountedMileage: mountedMileage ?? this.mountedMileage,
      unmountedDate: unmountedDate ?? this.unmountedDate,
      unmountedMileage: unmountedMileage ?? this.unmountedMileage,
    );
  }

  factory TireMountHistory.fromMap(Map<String, dynamic> map) {
    return TireMountHistory(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      tireSetId: map['tire_set_id'] as String,
      mountedDate: DateTime.parse(map['mounted_date'] as String),
      mountedMileage: map['mounted_mileage'] as int,
      unmountedDate: map['unmounted_date'] == null
          ? null
          : DateTime.parse(map['unmounted_date'] as String),
      unmountedMileage: map['unmounted_mileage'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'tire_set_id': tireSetId,
      'mounted_date': mountedDate.toIso8601String(),
      'mounted_mileage': mountedMileage,
      'unmounted_date': unmountedDate?.toIso8601String(),
      'unmounted_mileage': unmountedMileage,
    };
  }
}
