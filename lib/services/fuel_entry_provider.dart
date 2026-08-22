import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/fuel_entry.dart';
import 'cloud_sync_service.dart';
import 'premium_provider.dart';
import 'vehicle_provider.dart';

final fuelEntryProvider =
    AsyncNotifierProvider<FuelEntryNotifier, List<FuelEntry>>(
      FuelEntryNotifier.new,
    );

class FuelEntryNotifier extends AsyncNotifier<List<FuelEntry>> {
  final AppDatabase _database = AppDatabase.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  @override
  Future<List<FuelEntry>> build() async {
    return _database.getFuelEntries();
  }

  Future<void> addFuelEntry(FuelEntry entry) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      debugPrint('⛽ MotorLog: Tankvorgang ${entry.id} wird lokal gespeichert.');

      await _database.insertFuelEntry(entry);

      debugPrint('✅ MotorLog: Tankvorgang ${entry.id} lokal gespeichert.');

      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );

      debugPrint(
        '☁️ MotorLog: Cloud-Prüfung für Tankvorgang ${entry.id} startet.',
      );

      await _tryUploadFuelEntry(entry);

      return _database.getFuelEntries();
    });
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateFuelEntry(entry);

      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );

      debugPrint(
        '☁️ MotorLog: Cloud-Prüfung für bearbeiteten '
        'Tankvorgang ${entry.id} startet.',
      );

      await _tryUploadFuelEntry(entry);

      return _database.getFuelEntries();
    });
  }

  Future<void> deleteFuelEntry(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteFuelEntry(id);

      await _tryDeleteFuelEntryFromCloud(id);

      return _database.getFuelEntries();
    });
  }

  Future<int> restoreFuelEntriesFromCloud() async {
    final isPremium = await ref.read(premiumProvider.future);

    if (!isPremium) {
      throw StateError(
        'Cloud-Wiederherstellung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    final cloudEntries = await _cloudSyncService.downloadFuelEntries();

    for (final entry in cloudEntries) {
      await _database.insertFuelEntry(entry);

      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );
    }

    state = AsyncData(await _database.getFuelEntries());

    return cloudEntries.length;
  }

  Future<void> uploadAllFuelEntriesToCloud() async {
    final isPremium = await ref.read(premiumProvider.future);

    if (!isPremium) {
      return;
    }

    final entries = await _database.getFuelEntries();

    if (entries.isEmpty) {
      return;
    }

    try {
      await _cloudSyncService.uploadFuelEntries(entries);

      debugPrint(
        '✅ MotorLog Cloud: ${entries.length} Tankvorgänge '
        'erfolgreich hochgeladen.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Tankvorgänge konnten nicht '
        'vollständig hochgeladen werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getFuelEntries);
  }

  // ---------------------------------------------------------------------------
  // CLOUD-HILFSMETHODEN
  // ---------------------------------------------------------------------------

  Future<void> _tryUploadFuelEntry(FuelEntry entry) async {
    try {
      final isPremium = await ref.read(premiumProvider.future);

      debugPrint(
        '☁️ MotorLog Cloud: Premium-Status beim Tankvorgang: $isPremium',
      );

      if (!isPremium) {
        debugPrint(
          'ℹ️ MotorLog Cloud: Tankvorgang ${entry.id} bleibt lokal, '
          'da Free aktiv ist.',
        );
        return;
      }

      debugPrint(
        '☁️ MotorLog Cloud: Upload Tankvorgang ${entry.id} wird gestartet.',
      );

      await _cloudSyncService.uploadFuelEntry(entry);

      debugPrint(
        '✅ MotorLog Cloud: Tankvorgang ${entry.id} '
        'erfolgreich hochgeladen.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Tankvorgang ${entry.id} '
        'konnte nicht hochgeladen werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _tryDeleteFuelEntryFromCloud(String id) async {
    try {
      final isPremium = await ref.read(premiumProvider.future);

      if (!isPremium) {
        return;
      }

      debugPrint('☁️ MotorLog Cloud: Löschen Tankvorgang $id wird gestartet.');

      await _cloudSyncService.deleteFuelEntry(id);

      debugPrint('✅ MotorLog Cloud: Tankvorgang $id erfolgreich gelöscht.');
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Tankvorgang $id konnte nicht '
        'aus der Cloud gelöscht werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }
}
