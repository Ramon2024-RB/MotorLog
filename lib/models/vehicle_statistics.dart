class VehicleStatistics {
  const VehicleStatistics({
    required this.totalDistance,
    required this.averageConsumption,
    required this.averageFuelPrice,
    required this.costPer100Km,
    required this.costPerKm,
    required this.totalFuel,
    required this.totalCost,
    required this.refuels,
  });

  final int totalDistance;
  final double averageConsumption;
  final double averageFuelPrice;
  final double costPer100Km;
  final double costPerKm;
  final double totalFuel;
  final double totalCost;
  final int refuels;
}