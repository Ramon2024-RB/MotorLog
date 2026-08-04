import '../models/fuel_entry.dart';
import '../models/vehicle_statistics.dart';

VehicleStatistics calculateVehicleStatistics(
  List<FuelEntry> entries,
) {
  if (entries.isEmpty) {
    return const VehicleStatistics(
      totalDistance: 0,
      averageConsumption: 0,
      averageFuelPrice: 0,
      costPer100Km: 0,
      costPerKm: 0,
      totalFuel: 0,
      totalCost: 0,
      refuels: 0,
    );
  }

  final sortedEntries = [...entries]
    ..sort((a, b) => a.mileage.compareTo(b.mileage));

  final totalFuel = sortedEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.liters,
  );

  final totalCost = sortedEntries.fold<double>(
    0,
    (sum, entry) => sum + entry.totalPrice,
  );

  final averageFuelPrice =
      totalFuel > 0 ? totalCost / totalFuel : 0.0;

  int totalDistance = 0;
  double consumedFuel = 0;

  FuelEntry? previousFullTank;

  for (final entry in sortedEntries) {
    if (!entry.isFullTank) {
      if (previousFullTank != null) {
        consumedFuel += entry.liters;
      }
      continue;
    }

    if (previousFullTank != null) {
      final distance = entry.mileage - previousFullTank.mileage;

      if (distance > 0) {
        totalDistance += distance;
        consumedFuel += entry.liters;
      }
    }

    previousFullTank = entry;
  }

  final averageConsumption = totalDistance > 0
      ? consumedFuel / totalDistance * 100
      : 0.0;

  final costPerKm =
      totalDistance > 0 ? totalCost / totalDistance : 0.0;

  final costPer100Km = costPerKm * 100;

  return VehicleStatistics(
    totalDistance: totalDistance,
    averageConsumption: averageConsumption,
    averageFuelPrice: averageFuelPrice,
    costPer100Km: costPer100Km,
    costPerKm: costPerKm,
    totalFuel: totalFuel,
    totalCost: totalCost,
    refuels: sortedEntries.length,
  );
}