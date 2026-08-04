import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_maintenance_dialog.dart';
import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';
import '../../services/maintenance_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_card.dart';

class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key, this.vehicleId});

  final String? vehicleId;

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddMaintenanceDialog(initialVehicleId: vehicleId);
      },
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    MaintenanceEntry entry,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddMaintenanceDialog(entry: entry);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MaintenanceEntry entry,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Wartung löschen?'),
          content: Text(
            'Möchtest du „${entry.title}“ wirklich löschen?\n\n'
            'Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Löschen'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(maintenanceProvider.notifier).deleteMaintenance(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceAsync = ref.watch(maintenanceProvider);
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wartungen',
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
          return maintenanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Wartungen konnten nicht geladen werden.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (entries) {
              final visibleEntries = vehicleId == null
                  ? entries
                  : entries
                        .where((entry) => entry.vehicleId == vehicleId)
                        .toList();

              final vehicleMap = {
                for (final vehicle in vehicles) vehicle.id: vehicle,
              };

              if (visibleEntries.isEmpty) {
                return _EmptyMaintenanceView(
                  onAddMaintenance: () {
                    _openAddDialog(context);
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () {
                  return ref.read(maintenanceProvider.notifier).reload();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: visibleEntries.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 14);
                  },
                  itemBuilder: (context, index) {
                    final entry = visibleEntries[index];
                    final vehicle = vehicleMap[entry.vehicleId];

                    return Dismissible(
                      key: ValueKey(entry.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _confirmDelete(context, ref, entry);

                        return false;
                      },
                      background: Container(
                        padding: const EdgeInsets.only(right: 24),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 30,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      child: _MaintenanceCard(
                        entry: entry,
                        vehicle: vehicle,
                        onTap: () {
                          _openEditDialog(context, entry);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Wartung'),
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard({
    required this.entry,
    required this.vehicle,
    required this.onTap,
  });

  final MaintenanceEntry entry;
  final Vehicle? vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  _categoryIcon(entry.category),
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle?.name ?? 'Unbekanntes Fahrzeug'} · '
                      '${_formatDate(entry.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MaintenanceValue(
                          label: 'Kategorie',
                          value: entry.category,
                        ),
                        _MaintenanceValue(
                          label: 'Kosten',
                          value: '${_formatNumber(entry.cost)} €',
                        ),
                        _MaintenanceValue(
                          label: 'Kilometer',
                          value: '${entry.mileage} km',
                        ),
                      ],
                    ),
                    if (entry.notes != null) ...[
                      const SizedBox(height: 12),
                      Text(entry.notes!),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Ölwechsel':
        return Icons.oil_barrel_outlined;
      case 'Inspektion':
        return Icons.fact_check_outlined;
      case 'Bremsen':
        return Icons.car_repair;
      case 'TÜV':
        return Icons.verified_outlined;
      case 'Zahnriemen':
        return Icons.settings_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  static String _formatNumber(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class _MaintenanceValue extends StatelessWidget {
  const _MaintenanceValue({required this.label, required this.value});

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

class _EmptyMaintenanceView extends StatelessWidget {
  const _EmptyMaintenanceView({required this.onAddMaintenance});

  final VoidCallback onAddMaintenance;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.build_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Wartungen',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erfasse deine erste Wartung.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddMaintenance,
              icon: const Icon(Icons.add),
              label: const Text('Wartung hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
