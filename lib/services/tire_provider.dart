import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/tire_set.dart';

final tireProvider = AsyncNotifierProvider<TireNotifier, List<TireSet>>(
  TireNotifier.new,
);

class TireNotifier extends AsyncNotifier<List<TireSet>> {
  @override
  Future<List<TireSet>> build() async {
    return AppDatabase.instance.getTireSets();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return AppDatabase.instance.getTireSets();
    });
  }

  Future<void> addTireSet(TireSet tireSet) async {
    await AppDatabase.instance.insertTireSet(tireSet);
    await reload();
  }

  Future<void> updateTireSet(TireSet tireSet) async {
    await AppDatabase.instance.updateTireSet(tireSet);
    await reload();
  }

  Future<void> deleteTireSet(String id) async {
    await AppDatabase.instance.deleteTireSet(id);
    await reload();
  }

  Future<void> setMountedTireSet({
    required String vehicleId,
    required String tireSetId,
  }) async {
    await AppDatabase.instance.setMountedTireSet(
      vehicleId: vehicleId,
      tireSetId: tireSetId,
    );

    await reload();
  }
}
