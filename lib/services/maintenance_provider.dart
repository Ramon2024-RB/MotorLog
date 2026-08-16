import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';
import 'notification_service.dart';
import 'vehicle_provider.dart';

class MaintenanceNotifier extends AsyncNotifier<List<MaintenanceEntry>> {
  final AppDatabase _database = AppDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;

  @override
  Future<List<MaintenanceEntry>> build() async {
    return _database.getMaintenanceEntries();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_database.getMaintenanceEntries);
  }

  Future<void> addMaintenance(MaintenanceEntry entry) async {
    await _database.insertMaintenanceEntry(entry);

    try {
      await _notificationService.scheduleMaintenanceNotification(entry);
    } catch (error) {
      // Die Wartung soll auch dann gespeichert bleiben,
      // wenn das Planen der Datumsbenachrichtigung fehlschlägt.
    }

    try {
      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );
    } catch (error) {
      // Die Wartung soll auch dann gespeichert bleiben,
      // wenn der Fahrzeug-Kilometerstand nicht automatisch
      // aktualisiert werden kann.
    }

    await reload();
  }

  Future<void> updateMaintenance(MaintenanceEntry entry) async {
    await _database.updateMaintenanceEntry(entry);

    try {
      await _notificationService.cancelMaintenanceNotification(entry.id);

      await _notificationService.scheduleMaintenanceNotification(entry);
    } catch (error) {
      // Die Änderung der Wartung soll auch dann gespeichert
      // bleiben, wenn die Datumsbenachrichtigung nicht
      // aktualisiert werden kann.
    }

    try {
      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );
    } catch (error) {
      // Die Änderung der Wartung soll auch dann gespeichert
      // bleiben, wenn der Fahrzeug-Kilometerstand nicht
      // automatisch aktualisiert werden kann.
    }

    await reload();
  }

  Future<void> deleteMaintenance(String id) async {
    await _database.deleteMaintenanceEntry(id);

    try {
      await _notificationService.cancelMaintenanceNotification(id);
    } catch (error) {
      // Die Wartung soll trotzdem gelöscht bleiben.
    }

    await reload();
  }
}

final maintenanceProvider =
    AsyncNotifierProvider<MaintenanceNotifier, List<MaintenanceEntry>>(
      MaintenanceNotifier.new,
    );
