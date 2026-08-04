import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/vehicle.dart';
import '../../services/expense_provider.dart';
import '../../services/vehicle_provider.dart';
import 'add_expense_dialog.dart';
import '../../widgets/motorlog/motorlog_card.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key, this.vehicleId});

  final String? vehicleId;

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const AddExpenseDialog();
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, Expense expense) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddExpenseDialog(expense: expense);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ausgabe löschen?'),
          content: Text('Möchtest du „${expense.title}“ wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kosten',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Fahrzeuge konnten nicht geladen werden.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
        data: (vehicles) {
          return expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Kosten konnten nicht geladen werden.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref.read(expenseProvider.notifier).reload();
                      },
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
            data: (expenses) {
              final visibleExpenses = vehicleId == null
                  ? expenses
                  : expenses
                        .where((expense) => expense.vehicleId == vehicleId)
                        .toList();
              if (vehicles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Lege zuerst ein Fahrzeug an, bevor du Kosten speicherst.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (visibleExpenses.isEmpty) {
                return _EmptyExpensesView(
                  onAddExpense: () => _openAddDialog(context),
                );
              }

              final vehicleMap = {
                for (final vehicle in vehicles) vehicle.id: vehicle,
              };

              return RefreshIndicator(
                onRefresh: () {
                  return ref.read(expenseProvider.notifier).reload();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: visibleExpenses.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final expense = visibleExpenses[index];
                    final vehicle = vehicleMap[expense.vehicleId];

                    return _ExpenseCard(
                      expense: expense,
                      vehicle: vehicle,
                      onEdit: () {
                        _openEditDialog(context, expense);
                      },
                      onDelete: () {
                        _confirmDelete(context, ref, expense);
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ausgabe'),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final Vehicle? vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError, size: 30),
      ),
      child: MotorLogCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    _categoryIcon(expense.category),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle?.name ?? 'Unbekanntes Fahrzeug'} · '
                        '${_formatDate(expense.date)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _ExpenseValue(
                            label: 'Kategorie',
                            value: expense.category,
                          ),
                          _ExpenseValue(
                            label: 'Betrag',
                            value: '${_formatNumber(expense.amount, 2)} €',
                          ),
                          if (expense.mileage != null)
                            _ExpenseValue(
                              label: 'Kilometer',
                              value: '${expense.mileage} km',
                            ),
                        ],
                      ),
                      if (expense.notes != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes, size: 17),
                            const SizedBox(width: 6),
                            Expanded(child: Text(expense.notes!)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Antippen zum Bearbeiten',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Wartung':
        return Icons.build_outlined;
      case 'Reparatur':
        return Icons.handyman_outlined;
      case 'Reifen':
        return Icons.tire_repair;
      case 'Versicherung':
        return Icons.shield_outlined;
      case 'Steuer':
        return Icons.account_balance_outlined;
      case 'TÜV':
        return Icons.fact_check_outlined;
      case 'Parken':
        return Icons.local_parking;
      case 'Maut':
        return Icons.route;
      case 'Camping':
        return Icons.cabin_outlined;
      case 'Zubehör':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  static String _formatNumber(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }
}

class _ExpenseValue extends StatelessWidget {
  const _ExpenseValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyExpensesView extends StatelessWidget {
  const _EmptyExpensesView({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Kosten',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erfasse deine erste Ausgabe.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Ausgabe hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
