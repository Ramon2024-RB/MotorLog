import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';

class MaintenanceNotifier extends AsyncNotifier<List<MaintenanceEntry>> {
  final AppDatabase _database = AppDatabase.instance;

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
    await reload();
  }

  Future<void> updateMaintenance(MaintenanceEntry entry) async {
    await _database.updateMaintenanceEntry(entry);
    await reload();
  }

  Future<void> deleteMaintenance(String id) async {
    await _database.deleteMaintenanceEntry(id);
    await reload();
  }
}

final maintenanceProvider =
    AsyncNotifierProvider<MaintenanceNotifier, List<MaintenanceEntry>>(
      MaintenanceNotifier.new,
    );
