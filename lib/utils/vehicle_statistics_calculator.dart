import '../models/expense.dart';
import '../models/fuel_consumption_interval.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import '../models/vehicle_statistics.dart';

/// Berechnet die einzelnen auswertbaren Verbrauchsintervalle.
///
/// Ein Verbrauchsintervall beginnt mit einer Volltankung und endet
/// mit der nächsten Volltankung.
///
/// Teilbetankungen zwischen diesen beiden Volltankungen werden dem
/// Intervall vollständig zugerechnet.
List<FuelConsumptionInterval> calculateFuelConsumptionIntervals(
  List<FuelEntry> fuelEntries,
) {
  final sortedFuelEntries = [...fuelEntries]
    ..sort((a, b) => a.mileage.compareTo(b.mileage));

  final intervals = <FuelConsumptionInterval>[];

  FuelEntry? previousFullTank;
  double fuelSincePreviousFullTank = 0;

  for (final entry in sortedFuelEntries) {
    // Solange noch keine erste Volltankung vorhanden ist,
    // können wir noch keinen Verbrauch berechnen.
    if (previousFullTank == null) {
      if (entry.isFullTank) {
        previousFullTank = entry;
        fuelSincePreviousFullTank = 0;
      }

      continue;
    }

    // Jede Tankmenge nach der vorherigen Volltankung gehört
    // zum aktuellen Verbrauchsintervall.
    fuelSincePreviousFullTank += entry.liters;

    // Bei einer Teilbetankung läuft das Intervall einfach weiter.
    if (!entry.isFullTank) {
      continue;
    }

    final distance = entry.mileage - previousFullTank.mileage;

    if (distance > 0 && fuelSincePreviousFullTank > 0) {
      final consumption = fuelSincePreviousFullTank / distance * 100;

      intervals.add(
        FuelConsumptionInterval(
          startMileage: previousFullTank.mileage,
          endMileage: entry.mileage,
          distance: distance,
          consumedFuel: fuelSincePreviousFullTank,
          consumption: consumption,
          date: entry.date,
        ),
      );
    }

    // Die aktuelle Volltankung ist gleichzeitig der Startpunkt
    // für das nächste Verbrauchsintervall.
    previousFullTank = entry;
    fuelSincePreviousFullTank = 0;
  }

  return intervals;
}

VehicleStatistics calculateVehicleStatistics({
  required List<FuelEntry> fuelEntries,
  required List<Expense> expenses,
  required List<MaintenanceEntry> maintenanceEntries,
}) {
  final sortedFuelEntries = [...fuelEntries]
    ..sort((a, b) => a.mileage.compareTo(b.mileage));

  // ---------------------------------------------------------------------------
  // Tankdaten
  // ---------------------------------------------------------------------------

  final totalFuel = sortedFuelEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.liters,
  );

  final totalFuelCost = sortedFuelEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalPrice,
  );

  final averageFuelPrice = totalFuel > 0 ? totalFuelCost / totalFuel : 0.0;

  // ---------------------------------------------------------------------------
  // Verbrauch und ausgewertete Strecke
  // ---------------------------------------------------------------------------

  final consumptionIntervals = calculateFuelConsumptionIntervals(
    sortedFuelEntries,
  );

  final totalDistance = consumptionIntervals.fold<int>(
    0,
    (sum, interval) => sum + interval.distance,
  );

  final consumedFuel = consumptionIntervals.fold<double>(
    0,
    (sum, interval) => sum + interval.consumedFuel,
  );

  final averageConsumption = totalDistance > 0
      ? consumedFuel / totalDistance * 100
      : 0.0;

  // ---------------------------------------------------------------------------
  // Sonstige Kosten
  // ---------------------------------------------------------------------------

  final totalExpenseCost = expenses.fold<double>(
    0,
    (sum, expense) => sum + expense.amount,
  );

  // ---------------------------------------------------------------------------
  // Wartungskosten
  // ---------------------------------------------------------------------------

  final totalMaintenanceCost = maintenanceEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.cost,
  );

  // ---------------------------------------------------------------------------
  // Gesamtkosten
  // ---------------------------------------------------------------------------

  final totalVehicleCost =
      totalFuelCost + totalExpenseCost + totalMaintenanceCost;

  final costPerKm = totalDistance > 0 ? totalVehicleCost / totalDistance : 0.0;

  final costPer100Km = costPerKm * 100;

  // ---------------------------------------------------------------------------
  // Ergebnis
  // ---------------------------------------------------------------------------

  return VehicleStatistics(
    totalDistance: totalDistance,
    averageConsumption: averageConsumption,
    averageFuelPrice: averageFuelPrice,
    costPer100Km: costPer100Km,
    costPerKm: costPerKm,
    totalFuel: totalFuel,
    totalFuelCost: totalFuelCost,
    totalExpenseCost: totalExpenseCost,
    totalMaintenanceCost: totalMaintenanceCost,
    totalVehicleCost: totalVehicleCost,
    refuels: sortedFuelEntries.length,
    expenses: expenses.length,
    maintenanceEntries: maintenanceEntries.length,
  );
}
