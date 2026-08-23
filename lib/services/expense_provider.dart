import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/expense.dart';
import 'cloud_sync_service.dart';
import 'premium_provider.dart';

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  final AppDatabase _database = AppDatabase.instance;
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  @override
  Future<List<Expense>> build() async {
    return _database.getExpenses();
  }

  Future<bool> _isPremium() async {
    return ref.read(premiumProvider.future);
  }

  Future<void> addExpense(Expense expense) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      debugPrint('💶 MotorLog: Kosten ${expense.id} werden lokal gespeichert.');

      await _database.insertExpense(expense);

      debugPrint('✅ MotorLog: Kosten ${expense.id} lokal gespeichert.');

      await _tryUploadExpense(expense);

      return _database.getExpenses();
    });
  }

  Future<void> updateExpense(Expense expense) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateExpense(expense);

      debugPrint(
        '☁️ MotorLog: Cloud-Prüfung für bearbeitete Kosten '
        '${expense.id} startet.',
      );

      await _tryUploadExpense(expense);

      return _database.getExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteExpense(id);

      await _tryDeleteExpenseFromCloud(id);

      return _database.getExpenses();
    });
  }

  Future<int> restoreExpensesFromCloud() async {
    final isPremium = await _isPremium();

    if (!isPremium) {
      throw StateError(
        'Cloud-Wiederherstellung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    debugPrint('☁️ MotorLog Cloud: Kosten-Download wird gestartet.');

    final cloudExpenses = await _cloudSyncService.downloadExpenses();

    debugPrint(
      '☁️ MotorLog Cloud: ${cloudExpenses.length} Kosten-Eintrag/Einträge '
      'aus der Cloud geladen.',
    );

    for (final expense in cloudExpenses) {
      await _database.insertExpense(expense);

      debugPrint(
        '📱 MotorLog lokal: Kosten "${expense.title}" '
        'wurden gespeichert/wiederhergestellt.',
      );
    }

    state = AsyncData(await _database.getExpenses());

    debugPrint(
      '✅ MotorLog Cloud: ${cloudExpenses.length} Kosten-Eintrag/Einträge '
      'erfolgreich lokal wiederhergestellt.',
    );

    return cloudExpenses.length;
  }

  Future<void> uploadAllExpensesToCloud() async {
    final isPremium = await _isPremium();

    if (!isPremium) {
      throw StateError(
        'Cloud-Synchronisierung ist nur mit MotorLog Premium verfügbar.',
      );
    }

    final expenses = await _database.getExpenses();

    await _cloudSyncService.uploadExpenses(expenses);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getExpenses);
  }

  // ---------------------------------------------------------------------------
  // CLOUD-HILFSMETHODEN
  // ---------------------------------------------------------------------------

  Future<void> _tryUploadExpense(Expense expense) async {
    debugPrint('☁️ MotorLog: Cloud-Prüfung für Kosten ${expense.id} startet.');

    try {
      final isPremium = await _isPremium();

      debugPrint('☁️ MotorLog Cloud: Premium-Status bei Kosten: $isPremium');

      if (!isPremium) {
        return;
      }

      debugPrint(
        '☁️ MotorLog Cloud: Upload Kosten ${expense.id} wird gestartet.',
      );

      await _cloudSyncService.uploadExpense(expense);

      debugPrint(
        '✅ MotorLog Cloud: Kosten ${expense.id} erfolgreich hochgeladen.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Kosten ${expense.id} '
        'konnten nicht hochgeladen werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }

  Future<void> _tryDeleteExpenseFromCloud(String id) async {
    try {
      final isPremium = await _isPremium();

      if (!isPremium) {
        return;
      }

      debugPrint('☁️ MotorLog Cloud: Löschen Kosten $id wird gestartet.');

      await _cloudSyncService.deleteExpense(id);

      debugPrint('✅ MotorLog Cloud: Kosten $id erfolgreich gelöscht.');
    } catch (error, stackTrace) {
      debugPrint(
        '❌ MotorLog Cloud: Kosten $id konnten nicht aus der Cloud '
        'gelöscht werden.',
      );
      debugPrint('❌ Fehler: $error');
      debugPrint('❌ StackTrace: $stackTrace');
    }
  }
}
