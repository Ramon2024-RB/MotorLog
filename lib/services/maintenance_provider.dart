import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/maintenance_entry.dart';
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
  // WARTUNG HINZUFÜGEN
  // ---------------------------------------------------------------------------

  Future<void> addMaintenance(MaintenanceEntry entry) async {
    debugPrint('🔧 MotorLog: Wartung "${entry.title}" wird lokal gespeichert.');

    await _database.insertMaintenanceEntry(entry);

    debugPrint('✅ MotorLog: Wartung "${entry.title}" lokal gespeichert.');

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

    await _tryUploadMaintenanceEntry(entry);

    await reload();
  }

  // ---------------------------------------------------------------------------
  // WARTUNG AKTUALISIEREN
  // ---------------------------------------------------------------------------

  Future<void> updateMaintenance(MaintenanceEntry entry) async {
    await _database.updateMaintenanceEntry(entry);

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

    await _tryUploadMaintenanceEntry(entry);

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

    debugPrint(
      '☁️ MotorLog Cloud: Backup von ${entries.length} Wartung(en) '
      'wird gestartet.',
    );

    if (entries.isEmpty) {
      debugPrint(
        'ℹ️ MotorLog Cloud: Keine lokalen Wartungen zum Sichern vorhanden.',
      );
      return;
    }

    await _cloudSyncService.uploadMaintenanceEntries(entries);

    debugPrint(
      '✅ MotorLog Cloud: ${entries.length} Wartung(en) '
      'erfolgreich gesichert.',
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

    debugPrint(
      '☁️ MotorLog Cloud: ${cloudEntries.length} Wartung(en) '
      'aus der Cloud geladen.',
    );

    for (final entry in cloudEntries) {
      await _database.insertMaintenanceEntry(entry);

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
  // CLOUD-HILFSMETHODEN
  // ---------------------------------------------------------------------------

  Future<void> _tryUploadMaintenanceEntry(MaintenanceEntry entry) async {
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

      debugPrint(
        '✅ MotorLog Cloud: Wartung "${entry.title}" '
        'erfolgreich hochgeladen.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Wartung "${entry.title}" '
        'konnte nicht hochgeladen werden.',
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
