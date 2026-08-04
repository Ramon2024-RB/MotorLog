import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/expense.dart';

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<Expense>>(
  ExpenseNotifier.new,
);

class ExpenseNotifier extends AsyncNotifier<List<Expense>> {
  final AppDatabase _database = AppDatabase.instance;

  @override
  Future<List<Expense>> build() async {
    return _database.getExpenses();
  }

  Future<void> addExpense(Expense expense) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.insertExpense(expense);
      return _database.getExpenses();
    });
  }

  Future<void> updateExpense(Expense expense) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.updateExpense(expense);
      return _database.getExpenses();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _database.deleteExpense(id);
      return _database.getExpenses();
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getExpenses);
  }
}