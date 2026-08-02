import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/vehicle.dart';

final vehicleProvider =
    AsyncNotifierProvider<VehicleNotifier, List<Vehicle>>(
  VehicleNotifier.new,
);

class VehicleNotifier extends AsyncNotifier<List<Vehicle>> {
  final AppDatabase _database = AppDatabase.instance;

  @override
  Future<List<Vehicle>> build() async {
    return _database.getVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.insertVehicle(vehicle);
      return _database.getVehicles();
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateVehicle(vehicle);
      return _database.getVehicles();
    });
  }

  Future<void> deleteVehicle(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteVehicle(id);
      return _database.getVehicles();
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getVehicles);
  }
}