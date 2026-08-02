import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/fuel_entry.dart';

final fuelEntryProvider =
    AsyncNotifierProvider<FuelEntryNotifier, List<FuelEntry>>(
  FuelEntryNotifier.new,
);

class FuelEntryNotifier extends AsyncNotifier<List<FuelEntry>> {
  final AppDatabase _database = AppDatabase.instance;

  @override
  Future<List<FuelEntry>> build() async {
    return _database.getFuelEntries();
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.insertFuelEntry(entry);
      return _database.getFuelEntries();
    });
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateFuelEntry(entry);
      return _database.getFuelEntries();
    });
  }

  Future<void> deleteFuelEntry(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteFuelEntry(id);
      return _database.getFuelEntries();
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getFuelEntries);
  }
}