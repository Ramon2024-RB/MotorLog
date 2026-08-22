import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';
import '../models/vehicle.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';

final vehicleProvider = AsyncNotifierProvider<VehicleNotifier, List<Vehicle>>(
  VehicleNotifier.new,
);

class VehicleNotifier extends AsyncNotifier<List<Vehicle>> {
  final AppDatabase _database = AppDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  static const int _maintenanceAdvanceKilometers = 500;

  @override
  Future<List<Vehicle>> build() async {
    return _database.getVehicles();
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUG HINZUFÜGEN
  // ---------------------------------------------------------------------------

  Future<void> addVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.insertVehicle(vehicle);

      await _checkMileageMaintenanceNotifications(vehicle);

      await _tryUploadVehicle(vehicle);

      return _database.getVehicles();
    });
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUG AKTUALISIEREN
  // ---------------------------------------------------------------------------

  Future<void> updateVehicle(Vehicle vehicle) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateVehicle(vehicle);

      await _checkMileageMaintenanceNotifications(vehicle);

      await _tryUploadVehicle(vehicle);

      return _database.getVehicles();
    });
  }

  // ---------------------------------------------------------------------------
  // KILOMETERSTAND AKTUALISIEREN
  // ---------------------------------------------------------------------------

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

    await _tryUploadVehicle(updatedVehicle);

    state = AsyncData(await _database.getVehicles());
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUG LÖSCHEN
  // ---------------------------------------------------------------------------

  Future<void> deleteVehicle(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteVehicle(id);

      await _tryDeleteCloudVehicle(id);

      return _database.getVehicles();
    });
  }

  // ---------------------------------------------------------------------------
  // STANDARDFAHRZEUG
  // ---------------------------------------------------------------------------

  Future<void> setDefaultVehicle(String vehicleId) async {
    state = const AsyncLoading<List<Vehicle>>();

    state = await AsyncValue.guard(() async {
      await _database.setDefaultVehicle(vehicleId);

      final vehicles = await _database.getVehicles();

      await _tryUploadVehicles(vehicles);

      return vehicles;
    });
  }

  // ---------------------------------------------------------------------------
  // LOKALE DATEN NEU LADEN
  // ---------------------------------------------------------------------------

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_database.getVehicles);
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUGE AUS DER CLOUD WIEDERHERSTELLEN
  // ---------------------------------------------------------------------------

  Future<int> restoreVehiclesFromCloud() async {
    debugPrint('☁️ MotorLog Cloud: Fahrzeug-Download wird gestartet.');

    final cloudVehicles = await _cloudSyncService.downloadVehicles();

    debugPrint(
      '☁️ MotorLog Cloud: ${cloudVehicles.length} Fahrzeug(e) '
      'aus der Cloud geladen.',
    );

    if (cloudVehicles.isEmpty) {
      state = AsyncData(await _database.getVehicles());

      debugPrint(
        'ℹ️ MotorLog Cloud: Keine Fahrzeuge zum Wiederherstellen vorhanden.',
      );

      return 0;
    }

    for (final vehicle in cloudVehicles) {
      await _database.insertVehicle(vehicle);

      debugPrint(
        '📱 MotorLog lokal: Fahrzeug "${vehicle.name}" '
        'wurde gespeichert/wiederhergestellt.',
      );
    }

    final localVehicles = await _database.getVehicles();

    state = AsyncData(localVehicles);

    debugPrint(
      '✅ MotorLog Cloud: ${cloudVehicles.length} Fahrzeug(e) '
      'erfolgreich lokal wiederhergestellt.',
    );

    return cloudVehicles.length;
  }

  // ---------------------------------------------------------------------------
  // CLOUD-UPLOAD
  // ---------------------------------------------------------------------------

  Future<void> _tryUploadVehicle(Vehicle vehicle) async {
    try {
      debugPrint(
        '☁️ MotorLog Cloud: Upload Fahrzeug "${vehicle.name}" wird gestartet.',
      );

      await _cloudSyncService.uploadVehicle(vehicle);

      debugPrint(
        '✅ MotorLog Cloud: Fahrzeug "${vehicle.name}" '
        'erfolgreich hochgeladen.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Fahrzeug "${vehicle.name}" konnte nicht '
        'hochgeladen werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _tryUploadVehicles(List<Vehicle> vehicles) async {
    try {
      debugPrint(
        '☁️ MotorLog Cloud: ${vehicles.length} Fahrzeuge '
        'werden synchronisiert.',
      );

      await _cloudSyncService.uploadVehicles(vehicles);

      debugPrint('✅ MotorLog Cloud: Fahrzeuge erfolgreich synchronisiert.');
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Fahrzeuge konnten nicht synchronisiert werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _tryDeleteCloudVehicle(String vehicleId) async {
    try {
      debugPrint(
        '☁️ MotorLog Cloud: Fahrzeug $vehicleId wird aus der Cloud gelöscht.',
      );

      await _cloudSyncService.deleteVehicle(vehicleId);

      debugPrint(
        '✅ MotorLog Cloud: Fahrzeug erfolgreich aus der Cloud gelöscht.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Fahrzeug konnte nicht aus der Cloud '
        'gelöscht werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  // ---------------------------------------------------------------------------
  // WARTUNGSBENACHRICHTIGUNGEN
  // ---------------------------------------------------------------------------

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
