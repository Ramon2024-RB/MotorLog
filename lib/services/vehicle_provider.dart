import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';
import '../models/vehicle.dart';
import 'notification_service.dart';

final vehicleProvider = AsyncNotifierProvider<VehicleNotifier, List<Vehicle>>(
  VehicleNotifier.new,
);

class VehicleNotifier extends AsyncNotifier<List<Vehicle>> {
  final AppDatabase _database = AppDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;

  static const int _maintenanceAdvanceKilometers = 500;

  @override
  Future<List<Vehicle>> build() async {
    return _database.getVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.insertVehicle(vehicle);

      await _checkMileageMaintenanceNotifications(vehicle);

      return _database.getVehicles();
    });
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateVehicle(vehicle);

      await _checkMileageMaintenanceNotifications(vehicle);

      return _database.getVehicles();
    });
  }

  Future<void> updateMileageIfHigher({
    required String vehicleId,
    required int mileage,
  }) async {
    final vehicles = await _database.getVehicles();

    Vehicle? vehicle;

    for (final item in vehicles) {
      if (item.id == vehicleId) {
        vehicle = item;
        break;
      }
    }

    if (vehicle == null) {
      return;
    }

    if (mileage <= vehicle.mileage) {
      return;
    }

    final updatedVehicle = Vehicle(
      id: vehicle.id,
      name: vehicle.name,
      brand: vehicle.brand,
      model: vehicle.model,
      year: vehicle.year,
      fuelType: vehicle.fuelType,
      mileage: mileage,
      licensePlate: vehicle.licensePlate,
      vehicleType: vehicle.vehicleType,
      isDefault: vehicle.isDefault,
    );

    await _database.updateVehicle(updatedVehicle);

    await _checkMileageMaintenanceNotifications(updatedVehicle);

    state = AsyncData(await _database.getVehicles());
  }

  Future<void> deleteVehicle(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteVehicle(id);
      return _database.getVehicles();
    });
  }

  Future<void> setDefaultVehicle(String vehicleId) async {
    state = const AsyncLoading<List<Vehicle>>();

    state = await AsyncValue.guard(() async {
      await _database.setDefaultVehicle(vehicleId);
      return _database.getVehicles();
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_database.getVehicles);
  }

  Future<void> _checkMileageMaintenanceNotifications(Vehicle vehicle) async {
    final maintenanceEntries = await _database.getMaintenanceEntries(
      vehicleId: vehicle.id,
    );

    for (final entry in maintenanceEntries) {
      await _checkMileageMaintenanceEntry(vehicle: vehicle, entry: entry);
    }
  }

  Future<void> _checkMileageMaintenanceEntry({
    required Vehicle vehicle,
    required MaintenanceEntry entry,
  }) async {
    final nextMileage = entry.nextMileage;

    if (nextMileage == null) {
      return;
    }

    final remainingKilometers = nextMileage - vehicle.mileage;

    if (remainingKilometers <= 0) {
      if (!entry.mileageDueNotified) {
        try {
          await _notificationService.showMileageDueNotification(
            entry: entry,
            currentMileage: vehicle.mileage,
          );

          await _database.updateMaintenanceMileageNotificationStatus(
            maintenanceId: entry.id,
            advanceNotified: true,
            dueNotified: true,
          );
        } catch (_) {
          // Status wird nur gespeichert, wenn die
          // Benachrichtigung erfolgreich ausgelöst wurde.
        }
      }

      return;
    }

    if (remainingKilometers <= _maintenanceAdvanceKilometers) {
      if (!entry.mileageAdvanceNotified) {
        try {
          await _notificationService.showMileageAdvanceNotification(
            entry: entry,
            currentMileage: vehicle.mileage,
          );

          await _database.updateMaintenanceMileageNotificationStatus(
            maintenanceId: entry.id,
            advanceNotified: true,
          );
        } catch (_) {
          // Beim nächsten höheren Kilometerstand kann
          // MotorLog die Benachrichtigung erneut versuchen.
        }
      }
    }
  }
}
