import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/vehicle_document.dart';
import 'cloud_sync_service.dart';
import 'premium_provider.dart';

final documentProvider =
    AsyncNotifierProvider<DocumentNotifier, List<VehicleDocument>>(
      DocumentNotifier.new,
    );

class DocumentNotifier extends AsyncNotifier<List<VehicleDocument>> {
  final AppDatabase _database = AppDatabase.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  @override
  Future<List<VehicleDocument>> build() async {
    return _database.getDocuments();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return _database.getDocuments();
    });
  }

  Future<void> addDocument(VehicleDocument document) async {
    debugPrint(
      '📄 MotorLog: Dokument "${document.title}" wird lokal gespeichert.',
    );

    await _database.insertDocument(document);

    debugPrint('✅ MotorLog: Dokument "${document.title}" lokal gespeichert.');

    await reload();

    await _syncDocumentToCloud(
      document,
      reason: 'neues Dokument "${document.title}"',
    );
  }

  Future<void> updateDocument(VehicleDocument document) async {
    debugPrint(
      '📄 MotorLog: Dokument "${document.title}" wird lokal aktualisiert.',
    );

    await _database.updateDocument(document);

    debugPrint('✅ MotorLog: Dokument "${document.title}" lokal aktualisiert.');

    await reload();

    await _syncDocumentToCloud(
      document,
      reason: 'bearbeitetes Dokument "${document.title}"',
    );
  }

  Future<void> deleteDocument(String id) async {
    final documents = await _database.getDocuments();

    VehicleDocument? document;

    for (final item in documents) {
      if (item.id == id) {
        document = item;
        break;
      }
    }

    await _database.deleteDocument(id);

    debugPrint('🗑️ MotorLog: Dokument $id lokal gelöscht.');

    await reload();

    final isPremium = await ref.read(premiumProvider.future);

    debugPrint(
      '☁️ MotorLog Cloud: Premium-Status beim Löschen eines Dokuments: '
      '$isPremium',
    );

    if (!isPremium) {
      return;
    }

    try {
      debugPrint('☁️ MotorLog Cloud: Löschen Dokument $id wird gestartet.');

      await _cloudSyncService.deleteDocument(id);

      debugPrint('✅ MotorLog Cloud: Dokument $id erfolgreich gelöscht.');
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Dokument $id konnte nicht gelöscht werden: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }

    if (document != null) {
      debugPrint(
        '✅ MotorLog: Dokument "${document.title}" vollständig gelöscht.',
      );
    }
  }

  Future<void> _syncDocumentToCloud(
    VehicleDocument document, {
    required String reason,
  }) async {
    final isPremium = await ref.read(premiumProvider.future);

    debugPrint('☁️ MotorLog Cloud: Premium-Status bei Dokument: $isPremium');

    if (!isPremium) {
      return;
    }

    try {
      debugPrint(
        '☁️ MotorLog Cloud: Dokument-Synchronisierung '
        '($reason) wird gestartet.',
      );

      await _cloudSyncService.uploadDocument(document);

      debugPrint(
        '✅ MotorLog Cloud: Dokument "${document.title}" '
        'erfolgreich synchronisiert.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Dokument "${document.title}" '
        'konnte nicht synchronisiert werden: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }

  Future<void> uploadAllDocumentsToCloud() async {
    final isPremium = await ref.read(premiumProvider.future);

    if (!isPremium) {
      throw StateError('Cloud-Backup ist nur mit MotorLog Premium verfügbar.');
    }

    final documents = await _database.getDocuments();

    debugPrint(
      '☁️ MotorLog Cloud: Backup von ${documents.length} '
      'Dokument(en) wird gestartet.',
    );

    await _cloudSyncService.uploadDocuments(documents);

    debugPrint(
      '✅ MotorLog Cloud: ${documents.length} Dokument(e) '
      'erfolgreich gesichert.',
    );
  }

  Future<int> restoreDocumentsFromCloud() async {
    final isPremium = await ref.read(premiumProvider.future);

    if (!isPremium) {
      throw StateError(
        'Cloud-Wiederherstellung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    debugPrint('☁️ MotorLog Cloud: Dokument-Download wird gestartet.');

    final cloudDocuments = await _cloudSyncService.downloadDocuments();

    debugPrint(
      '☁️ MotorLog Cloud: ${cloudDocuments.length} Dokument(e) '
      'aus der Cloud geladen.',
    );

    for (final document in cloudDocuments) {
      await _database.insertDocument(document);

      debugPrint(
        '📱 MotorLog lokal: Dokument "${document.title}" '
        'wurde gespeichert/wiederhergestellt.',
      );
    }

    state = AsyncData(await _database.getDocuments());

    debugPrint(
      '✅ MotorLog Cloud: ${cloudDocuments.length} Dokument(e) '
      'erfolgreich lokal wiederhergestellt.',
    );

    return cloudDocuments.length;
  }
}
