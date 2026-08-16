import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../models/tire_mount_history.dart';
import '../models/tire_set.dart';
import '../models/vehicle.dart';
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
      await _mountTireSet(
        vehicleId: tireSet.vehicleId,
        tireSetId: tireSet.id,
        requestedMileage: tireSet.mountedMileage,
        requestedDate: tireSet.mountedDate,
      );
    }

    await reload();
  }

  Future<void> updateTireSet(TireSet tireSet) async {
    final existingTireSets = await _database.getTireSets(
      vehicleId: tireSet.vehicleId,
    );

    TireSet? existingTireSet;

    for (final existing in existingTireSets) {
      if (existing.id == tireSet.id) {
        existingTireSet = existing;
        break;
      }
    }

    final wasMounted = existingTireSet?.isMounted ?? false;

    await _database.updateTireSet(tireSet);

    if (tireSet.isMounted && !wasMounted) {
      await _mountTireSet(
        vehicleId: tireSet.vehicleId,
        tireSetId: tireSet.id,
        requestedMileage: tireSet.mountedMileage,
        requestedDate: tireSet.mountedDate,
      );
    } else if (tireSet.isMounted) {
      await _database.setMountedTireSet(
        vehicleId: tireSet.vehicleId,
        tireSetId: tireSet.id,
      );

      await _updateVehicleMileageIfHigher(
        vehicleId: tireSet.vehicleId,
        mileage: tireSet.mountedMileage,
      );
    } else if (wasMounted) {
      await _finishActiveMount(vehicleId: tireSet.vehicleId);
    }

    await reload();
  }

  Future<void> deleteTireSet(String id) async {
    final allTireSets = await _database.getTireSets();

    TireSet? tireSet;

    for (final item in allTireSets) {
      if (item.id == id) {
        tireSet = item;
        break;
      }
    }

    if (tireSet != null && tireSet.isMounted) {
      await _finishActiveMount(vehicleId: tireSet.vehicleId);
    }

    await _database.deleteTireSet(id);

    await reload();
  }

  Future<void> setMountedTireSet({
    required String vehicleId,
    required String tireSetId,
    required int mileage,
    required DateTime mountedDate,
  }) async {
    final tireSets = await _database.getTireSets(vehicleId: vehicleId);

    TireSet? tireSet;

    for (final item in tireSets) {
      if (item.id == tireSetId) {
        tireSet = item;
        break;
      }
    }

    if (tireSet == null) {
      return;
    }

    if (tireSet.isMounted) {
      return;
    }

    await _mountTireSet(
      vehicleId: vehicleId,
      tireSetId: tireSetId,
      requestedMileage: mileage,
      requestedDate: mountedDate,
    );

    await reload();
  }

  Future<List<TireMountHistory>> getTireMountHistory({
    required String tireSetId,
  }) async {
    return _database.getTireMountHistory(tireSetId: tireSetId);
  }

  Future<int> getTotalTireDistance({required TireSet tireSet}) async {
    final completedDistance = await _database.getCompletedTireDistance(
      tireSet.id,
    );

    if (!tireSet.isMounted || tireSet.mountedMileage == null) {
      return completedDistance;
    }

    final vehicle = await _findVehicle(tireSet.vehicleId);

    if (vehicle == null) {
      return completedDistance;
    }

    final activeDistance = vehicle.mileage - tireSet.mountedMileage!;

    if (activeDistance <= 0) {
      return completedDistance;
    }

    return completedDistance + activeDistance;
  }

  Future<void> _mountTireSet({
    required String vehicleId,
    required String tireSetId,
    int? requestedMileage,
    DateTime? requestedDate,
  }) async {
    final vehicle = await _findVehicle(vehicleId);

    if (vehicle == null) {
      return;
    }

    final mountMileage = _resolveMountMileage(
      vehicle: vehicle,
      requestedMileage: requestedMileage,
    );

    final mountDate = requestedDate ?? DateTime.now();

    final activeMount = await _database.getActiveTireMount(
      vehicleId: vehicleId,
    );

    if (activeMount != null && activeMount.tireSetId != tireSetId) {
      await _finishMount(
        history: activeMount,
        currentMileage: mountMileage,
        currentDate: mountDate,
      );
    }

    await _database.setMountedTireSet(
      vehicleId: vehicleId,
      tireSetId: tireSetId,
    );

    final tireSets = await _database.getTireSets(vehicleId: vehicleId);

    TireSet? mountedTireSet;

    for (final item in tireSets) {
      if (item.id == tireSetId) {
        mountedTireSet = item;
        break;
      }
    }

    if (mountedTireSet != null) {
      final updatedTireSet = mountedTireSet.copyWith(
        isMounted: true,
        mountedMileage: mountMileage,
        mountedDate: mountDate,
      );

      await _database.updateTireSet(updatedTireSet);

      await _database.setMountedTireSet(
        vehicleId: vehicleId,
        tireSetId: tireSetId,
      );
    }

    final existingActiveMount = await _database.getActiveTireMount(
      vehicleId: vehicleId,
    );

    if (existingActiveMount == null ||
        existingActiveMount.tireSetId != tireSetId) {
      final history = TireMountHistory(
        id: const Uuid().v4(),
        vehicleId: vehicleId,
        tireSetId: tireSetId,
        mountedDate: mountDate,
        mountedMileage: mountMileage,
      );

      await _database.insertTireMountHistory(history);
    }

    await _updateVehicleMileageIfHigher(
      vehicleId: vehicleId,
      mileage: mountMileage,
    );
  }

  Future<void> _finishActiveMount({required String vehicleId}) async {
    final activeMount = await _database.getActiveTireMount(
      vehicleId: vehicleId,
    );

    if (activeMount == null) {
      return;
    }

    final vehicle = await _findVehicle(vehicleId);

    if (vehicle == null) {
      return;
    }

    await _finishMount(
      history: activeMount,
      currentMileage: vehicle.mileage,
      currentDate: DateTime.now(),
    );
  }

  Future<void> _finishMount({
    required TireMountHistory history,
    required int currentMileage,
    required DateTime currentDate,
  }) async {
    var unmountedMileage = currentMileage;

    if (unmountedMileage < history.mountedMileage) {
      unmountedMileage = history.mountedMileage;
    }

    final finishedHistory = TireMountHistory(
      id: history.id,
      vehicleId: history.vehicleId,
      tireSetId: history.tireSetId,
      mountedDate: history.mountedDate,
      mountedMileage: history.mountedMileage,
      unmountedDate: currentDate,
      unmountedMileage: unmountedMileage,
    );

    await _database.updateTireMountHistory(finishedHistory);
  }

  Future<Vehicle?> _findVehicle(String vehicleId) async {
    final vehicles = await _database.getVehicles();

    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  int _resolveMountMileage({required Vehicle vehicle, int? requestedMileage}) {
    if (requestedMileage == null) {
      return vehicle.mileage;
    }

    if (requestedMileage < vehicle.mileage) {
      return vehicle.mileage;
    }

    return requestedMileage;
  }

  Future<void> _updateVehicleMileageIfHigher({
    required String vehicleId,
    required int? mileage,
  }) async {
    if (mileage == null) {
      return;
    }

    await ref
        .read(vehicleProvider.notifier)
        .updateMileageIfHigher(vehicleId: vehicleId, mileage: mileage);
  }
}
