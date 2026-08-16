import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/tire_set.dart';
import 'vehicle_provider.dart';

final tireProvider = AsyncNotifierProvider<TireNotifier, List<TireSet>>(
  TireNotifier.new,
);

class TireNotifier extends AsyncNotifier<List<TireSet>> {
  final AppDatabase _database = AppDatabase.instance;

  @override
  Future<List<TireSet>> build() async {
    return _database.getTireSets();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return _database.getTireSets();
    });
  }

  Future<void> addTireSet(TireSet tireSet) async {
    await _database.insertTireSet(tireSet);

    if (tireSet.isMounted) {
      await _database.setMountedTireSet(
        vehicleId: tireSet.vehicleId,
        tireSetId: tireSet.id,
      );

      await _updateVehicleMileageFromTireSet(tireSet);
    }

    await reload();
  }

  Future<void> updateTireSet(TireSet tireSet) async {
    await _database.updateTireSet(tireSet);

    if (tireSet.isMounted) {
      await _database.setMountedTireSet(
        vehicleId: tireSet.vehicleId,
        tireSetId: tireSet.id,
      );

      await _updateVehicleMileageFromTireSet(tireSet);
    }

    await reload();
  }

  Future<void> deleteTireSet(String id) async {
    await _database.deleteTireSet(id);

    await reload();
  }

  Future<void> setMountedTireSet({
    required String vehicleId,
    required String tireSetId,
  }) async {
    await _database.setMountedTireSet(
      vehicleId: vehicleId,
      tireSetId: tireSetId,
    );

    final tireSets = await _database.getTireSets(vehicleId: vehicleId);

    TireSet? mountedTireSet;

    for (final tireSet in tireSets) {
      if (tireSet.id == tireSetId) {
        mountedTireSet = tireSet;
        break;
      }
    }

    if (mountedTireSet != null) {
      await _updateVehicleMileageFromTireSet(mountedTireSet);
    }

    await reload();
  }

  Future<void> _updateVehicleMileageFromTireSet(TireSet tireSet) async {
    final mountedMileage = tireSet.mountedMileage;

    if (mountedMileage == null) {
      return;
    }

    await ref
        .read(vehicleProvider.notifier)
        .updateMileageIfHigher(
          vehicleId: tireSet.vehicleId,
          mileage: mountedMileage,
        );
  }
}
