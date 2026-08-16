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

    // ---------------------------------------------------------------
    // Wartung ist bereits fällig oder überschritten.
    // ---------------------------------------------------------------

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
          // Wenn die Benachrichtigung nicht angezeigt werden kann,
          // wird der Status absichtlich nicht gespeichert.
          //
          // Dadurch kann MotorLog die Benachrichtigung beim nächsten
          // Aktualisieren des Kilometerstands erneut versuchen.
        }
      }

      return;
    }

    // ---------------------------------------------------------------
    // Wartung liegt höchstens noch 500 km entfernt.
    // ---------------------------------------------------------------

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
          // Auch hier speichern wir den Status nur dann,
          // wenn die Benachrichtigung erfolgreich ausgelöst wurde.
        }
      }
    }
  }
}
