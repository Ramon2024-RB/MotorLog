import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';
import '../models/maintenance_work.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';
import 'premium_provider.dart';
import 'vehicle_provider.dart';

class MaintenanceNotifier extends AsyncNotifier<List<MaintenanceEntry>> {
  final AppDatabase _database = AppDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  @override
  Future<List<MaintenanceEntry>> build() async {
    return _database.getMaintenanceEntries();
  }

  Future<bool> _isPremium() async {
    return ref.read(premiumProvider.future);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getMaintenanceEntries);
  }

  // ---------------------------------------------------------------------------
  // WARTUNGSARBEITEN
  // ---------------------------------------------------------------------------

  Future<List<MaintenanceWork>> getWorksForMaintenance(
    String maintenanceEntryId,
  ) {
    return _database.getMaintenanceWorks(
      maintenanceEntryId: maintenanceEntryId,
    );
  }

  Future<void> _replaceLocalMaintenanceWorks(
    String maintenanceEntryId,
    List<MaintenanceWork> works,
  ) async {
    await _database.deleteMaintenanceWorksForEntry(maintenanceEntryId);

    for (final work in works) {
      await _database.insertMaintenanceWork(work);
    }
  }

  // ---------------------------------------------------------------------------
  // WARTUNG HINZUFÜGEN
  // ---------------------------------------------------------------------------

  Future<void> addMaintenance(
    MaintenanceEntry entry, {
    List<MaintenanceWork>? works,
  }) async {
    debugPrint('🔧 MotorLog: Wartung "${entry.title}" wird lokal gespeichert.');

    await _database.insertMaintenanceEntry(entry);

    if (works != null) {
      await _replaceLocalMaintenanceWorks(entry.id, works);
    }

    debugPrint('✅ MotorLog: Wartung "${entry.title}" lokal gespeichert.');

    if (works != null) {
      debugPrint(
        '✅ MotorLog: ${works.length} Wartungsarbeit(en) '
        'lokal gespeichert.',
      );
    }

    try {
      await _notificationService.scheduleMaintenanceNotification(entry);
    } catch (error) {
      debugPrint(
        '⚠️ MotorLog: Wartungsbenachrichtigung konnte nicht geplant werden.',
      );
      debugPrint('⚠️ Fehler: $error');
    }

    try {
      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );
    } catch (error) {
      debugPrint(
        '⚠️ MotorLog: Fahrzeug-Kilometerstand konnte nicht '
        'automatisch aktualisiert werden.',
      );
      debugPrint('⚠️ Fehler: $error');
    }

    await _tryUploadMaintenance(entry, works: works);

    await reload();
  }

  // ---------------------------------------------------------------------------
  // WARTUNG AKTUALISIEREN
  // ---------------------------------------------------------------------------

  Future<void> updateMaintenance(
    MaintenanceEntry entry, {
    List<MaintenanceWork>? works,
  }) async {
    await _database.updateMaintenanceEntry(entry);

    if (works != null) {
      await _replaceLocalMaintenanceWorks(entry.id, works);
    }

    try {
      await _notificationService.cancelMaintenanceNotification(entry.id);
      await _notificationService.scheduleMaintenanceNotification(entry);
    } catch (error) {
      debugPrint(
        '⚠️ MotorLog: Wartungsbenachrichtigung konnte nicht '
        'aktualisiert werden.',
      );
      debugPrint('⚠️ Fehler: $error');
    }

    try {
      await ref
          .read(vehicleProvider.notifier)
          .updateMileageIfHigher(
            vehicleId: entry.vehicleId,
            mileage: entry.mileage,
          );
    } catch (error) {
      debugPrint(
        '⚠️ MotorLog: Fahrzeug-Kilometerstand konnte nicht '
        'automatisch aktualisiert werden.',
      );
      debugPrint('⚠️ Fehler: $error');
    }

    debugPrint(
      '☁️ MotorLog: Cloud-Prüfung für bearbeitete Wartung '
      '"${entry.title}" startet.',
    );

    await _tryUploadMaintenance(entry, works: works);

    await reload();
  }

  // ---------------------------------------------------------------------------
  // WARTUNG LÖSCHEN
  // ---------------------------------------------------------------------------

  Future<void> deleteMaintenance(String id) async {
    await _database.deleteMaintenanceEntry(id);

    try {
      await _notificationService.cancelMaintenanceNotification(id);
    } catch (error) {
      debugPrint(
        '⚠️ MotorLog: Wartungsbenachrichtigung konnte nicht '
        'entfernt werden.',
      );
      debugPrint('⚠️ Fehler: $error');
    }

    await _tryDeleteMaintenanceEntryFromCloud(id);

    await reload();
  }

  // ---------------------------------------------------------------------------
  // ALLE LOKALEN WARTUNGEN IN DIE CLOUD SICHERN
  // ---------------------------------------------------------------------------

  Future<void> uploadAllMaintenanceEntriesToCloud() async {
    final isPremium = await _isPremium();

    if (!isPremium) {
      throw StateError(
        'Cloud-Synchronisierung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    final entries = await _database.getMaintenanceEntries();
    final works = await _database.getMaintenanceWorks();

    debugPrint(
      '☁️ MotorLog Cloud: Backup von ${entries.length} Wartung(en) '
      'und ${works.length} Wartungsarbeit(en) wird gestartet.',
    );

    if (entries.isNotEmpty) {
      await _cloudSyncService.uploadMaintenanceEntries(entries);
    }

    if (works.isNotEmpty) {
      await _cloudSyncService.uploadMaintenanceWorks(works);
    }

    if (entries.isEmpty && works.isEmpty) {
      debugPrint(
        'ℹ️ MotorLog Cloud: Keine lokalen Wartungen zum Sichern vorhanden.',
      );
      return;
    }

    debugPrint(
      '✅ MotorLog Cloud: ${entries.length} Wartung(en) und '
      '${works.length} Wartungsarbeit(en) erfolgreich gesichert.',
    );
  }

  // ---------------------------------------------------------------------------
  // WARTUNGEN AUS DER CLOUD WIEDERHERSTELLEN
  // ---------------------------------------------------------------------------

  Future<int> restoreMaintenanceEntriesFromCloud() async {
    final isPremium = await _isPremium();

    if (!isPremium) {
      throw StateError(
        'Cloud-Wiederherstellung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    debugPrint('☁️ MotorLog Cloud: Wartungs-Download wird gestartet.');

    final cloudEntries = await _cloudSyncService.downloadMaintenanceEntries();
    final cloudWorks = await _cloudSyncService.downloadMaintenanceWorks();

    debugPrint(
      '☁️ MotorLog Cloud: ${cloudEntries.length} Wartung(en) und '
      '${cloudWorks.length} Wartungsarbeit(en) aus der Cloud geladen.',
    );

    final worksByEntry = <String, List<MaintenanceWork>>{};

    for (final work in cloudWorks) {
      worksByEntry
          .putIfAbsent(work.maintenanceEntryId, () => <MaintenanceWork>[])
          .add(work);
    }

    for (final entry in cloudEntries) {
      await _database.insertMaintenanceEntry(entry);

      final entryWorks = worksByEntry[entry.id];

      if (entryWorks != null && entryWorks.isNotEmpty) {
        await _replaceLocalMaintenanceWorks(entry.id, entryWorks);

        debugPrint(
          '📱 MotorLog lokal: ${entryWorks.length} Wartungsarbeit(en) '
          'für "${entry.title}" wiederhergestellt.',
        );
      } else {
        final existingWorks = await _database.getMaintenanceWorks(
          maintenanceEntryId: entry.id,
        );

        if (existingWorks.isEmpty) {
          await _database.insertMaintenanceWork(
            MaintenanceWork(
              id: '${entry.id}_cloud_legacy',
              maintenanceEntryId: entry.id,
              type: _legacyCategoryToWorkType(entry.category),
              nextMileage: entry.nextMileage,
              nextDate: entry.nextDate,
              mileageAdvanceNotified: entry.mileageAdvanceNotified,
              mileageDueNotified: entry.mileageDueNotified,
            ),
          );

          debugPrint(
            'ℹ️ MotorLog lokal: Für ältere Cloud-Wartung '
            '"${entry.title}" wurde eine Legacy-Arbeit erzeugt.',
          );
        }
      }

      try {
        await _notificationService.cancelMaintenanceNotification(entry.id);
        await _notificationService.scheduleMaintenanceNotification(entry);
      } catch (error) {
        debugPrint(
          '⚠️ MotorLog: Benachrichtigung für wiederhergestellte Wartung '
          '"${entry.title}" konnte nicht aktualisiert werden.',
        );
      }

      try {
        await ref
            .read(vehicleProvider.notifier)
            .updateMileageIfHigher(
              vehicleId: entry.vehicleId,
              mileage: entry.mileage,
            );
      } catch (error) {
        debugPrint(
          '⚠️ MotorLog: Kilometerstand für wiederhergestellte Wartung '
          '"${entry.title}" konnte nicht aktualisiert werden.',
        );
      }

      debugPrint(
        '📱 MotorLog lokal: Wartung "${entry.title}" '
        'wurde gespeichert/wiederhergestellt.',
      );
    }

    state = AsyncData(await _database.getMaintenanceEntries());

    debugPrint(
      '✅ MotorLog Cloud: ${cloudEntries.length} Wartung(en) '
      'erfolgreich lokal wiederhergestellt.',
    );

    return cloudEntries.length;
  }

  // ---------------------------------------------------------------------------
  // LEGACY-KATEGORIEN
  // ---------------------------------------------------------------------------

  String _legacyCategoryToWorkType(String category) {
    switch (category) {
      case 'Ölwechsel':
        return 'oil_change';
      case 'Inspektion':
        return 'inspection';
      case 'Bremsen':
        return 'brakes_legacy';
      case 'TÜV':
        return 'inspection_hu';
      case 'Zahnriemen':
        return 'timing_belt';
      case 'Luftfilter':
        return 'air_filter';
      case 'Innenraumfilter':
        return 'cabin_filter';
      case 'Kraftstofffilter':
        return 'fuel_filter';
      case 'Zündkerzen':
        return 'spark_plugs';
      case 'Kühlmittel':
        return 'coolant';
      case 'Getriebeöl':
        return 'transmission_oil';
      case 'Sonstiges':
        return 'other';
      default:
        return 'other';
    }
  }

  // ---------------------------------------------------------------------------
  // CLOUD-HILFSMETHODEN
  // ---------------------------------------------------------------------------

  Future<void> _tryUploadMaintenance(
    MaintenanceEntry entry, {
    List<MaintenanceWork>? works,
  }) async {
    try {
      final isPremium = await _isPremium();

      debugPrint('☁️ MotorLog Cloud: Premium-Status bei Wartung: $isPremium');

      if (!isPremium) {
        return;
      }

      debugPrint(
        '☁️ MotorLog Cloud: Upload Wartung "${entry.title}" '
        'wird gestartet.',
      );

      await _cloudSyncService.uploadMaintenanceEntry(entry);

      if (works != null) {
        await _cloudSyncService.replaceMaintenanceWorks(entry.id, works);
      }

      debugPrint(
        '✅ MotorLog Cloud: Wartung "${entry.title}" '
        'erfolgreich hochgeladen.',
      );

      if (works != null) {
        debugPrint(
          '✅ MotorLog Cloud: ${works.length} Wartungsarbeit(en) '
          'für "${entry.title}" synchronisiert.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Wartung "${entry.title}" '
        'konnte nicht vollständig hochgeladen werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _tryDeleteMaintenanceEntryFromCloud(String id) async {
    try {
      final isPremium = await _isPremium();

      if (!isPremium) {
        return;
      }

      debugPrint('☁️ MotorLog Cloud: Löschen Wartung $id wird gestartet.');

      await _cloudSyncService.deleteMaintenanceEntry(id);

      debugPrint('✅ MotorLog Cloud: Wartung $id erfolgreich gelöscht.');
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Wartung $id konnte nicht aus der Cloud '
        'gelöscht werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }
}

final maintenanceProvider =
    AsyncNotifierProvider<MaintenanceNotifier, List<MaintenanceEntry>>(
      MaintenanceNotifier.new,
    );
