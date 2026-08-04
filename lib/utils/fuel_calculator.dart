import '../models/fuel_entry.dart';

class FuelCalculationResult {
  const FuelCalculationResult({
    required this.distance,
    required this.consumption,
    required this.costPer100Km,
    required this.costPerKm,
  });

  final int distance;
  final double consumption;
  final double costPer100Km;
  final double costPerKm;
}

FuelCalculationResult? calculateConsumption(
  FuelEntry previous,
  FuelEntry current,
) {
  if (!previous.isFullTank || !current.isFullTank) {
    return null;
  }

  final distance =
      current.mileage - previous.mileage;

  if (distance <= 0) {
    return null;
  }

  final consumption =
      current.liters / distance * 100;

  final costPer100 =
      current.totalPrice / distance * 100;

  final costPerKm =
      current.totalPrice / distance;

  return FuelCalculationResult(
    distance: distance,
    consumption: consumption,
    costPer100Km: costPer100,
    costPerKm: costPerKm,
  );
}