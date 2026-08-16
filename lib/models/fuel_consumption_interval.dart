class FuelConsumptionInterval {
  const FuelConsumptionInterval({
    required this.startMileage,
    required this.endMileage,
    required this.distance,
    required this.consumedFuel,
    required this.consumption,
    required this.date,
  });

  /// Kilometerstand der vorherigen Volltankung.
  final int startMileage;

  /// Kilometerstand der abschließenden Volltankung.
  final int endMileage;

  /// Gefahrene Strecke zwischen den Volltankungen.
  final int distance;

  /// Kraftstoffmenge, die diesem Intervall zugeordnet wird.
  final double consumedFuel;

  /// Verbrauch des Intervalls in l/100 km.
  final double consumption;

  /// Datum der abschließenden Volltankung.
  final DateTime date;
}
