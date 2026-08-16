class VehicleStatistics {
  const VehicleStatistics({
    required this.totalDistance,
    required this.averageConsumption,
    required this.averageFuelPrice,
    required this.costPer100Km,
    required this.costPerKm,
    required this.totalFuel,
    required this.totalFuelCost,
    required this.totalExpenseCost,
    required this.totalMaintenanceCost,
    required this.totalVehicleCost,
    required this.refuels,
    required this.expenses,
    required this.maintenanceEntries,
  });

  /// Kilometer, die anhand der Tankvorgänge
  /// zuverlässig ausgewertet werden konnten.
  final int totalDistance;

  /// Durchschnittlicher Verbrauch in l/100 km.
  final double averageConsumption;

  /// Durchschnittlicher Kraftstoffpreis pro Liter.
  final double averageFuelPrice;

  /// Gesamtkosten pro 100 km.
  final double costPer100Km;

  /// Gesamtkosten pro Kilometer.
  final double costPerKm;

  /// Insgesamt getankte Kraftstoffmenge.
  final double totalFuel;

  /// Summe aller Tankkosten.
  final double totalFuelCost;

  /// Summe aller normalen Ausgaben.
  final double totalExpenseCost;

  /// Summe aller Wartungskosten.
  final double totalMaintenanceCost;

  /// Gesamtkosten des Fahrzeugs:
  /// Tankkosten + Ausgaben + Wartungen.
  final double totalVehicleCost;

  /// Anzahl gespeicherter Tankvorgänge.
  final int refuels;

  /// Anzahl gespeicherter sonstiger Ausgaben.
  final int expenses;

  /// Anzahl gespeicherter Wartungen.
  final int maintenanceEntries;
}
