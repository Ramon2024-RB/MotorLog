import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';
import '../../services/maintenance_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../utils/maintenance_status_calculator.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_maintenance_dialog.dart';

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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Fahrzeuge konnten nicht geladen werden.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const _NoVehicleView();
          }

          return maintenanceAsync.when(
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
                      'Wartungen konnten nicht geladen werden.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref.read(maintenanceProvider.notifier).reload();
                      },
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) {
              final visibleEntries = vehicleId == null
                  ? [...entries]
                  : entries
                        .where((entry) => entry.vehicleId == vehicleId)
                        .toList();

              final vehicleMap = {
                for (final vehicle in vehicles) vehicle.id: vehicle,
              };

              visibleEntries.sort((first, second) {
                final firstStatus = calculateMaintenanceStatus(
                  entry: first,
                  vehicle: vehicleMap[first.vehicleId],
                );

                final secondStatus = calculateMaintenanceStatus(
                  entry: second,
                  vehicle: vehicleMap[second.vehicleId],
                );

                final statusComparison = firstStatus.priority.compareTo(
                  secondStatus.priority,
                );

                if (statusComparison != 0) {
                  return statusComparison;
                }

                return second.date.compareTo(first.date);
              });

              if (visibleEntries.isEmpty) {
                return _EmptyMaintenanceView(
                  onAddMaintenance: () => _openAddDialog(context),
                );
              }

              return RefreshIndicator(
                onRefresh: () {
                  return ref.read(maintenanceProvider.notifier).reload();
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 30,
                              color: Theme.of(context).colorScheme.onError,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: _MaintenanceCard(
                        entry: entry,
                        vehicle: vehicle,
                        onTap: () => _openEditDialog(context, entry),
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
        onPressed: () => _openAddDialog(context),
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

    final status = calculateMaintenanceStatus(entry: entry, vehicle: vehicle);

    final statusColor = _statusColor(context, status.type);

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
                radius: 27,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle?.name ?? 'Unbekanntes Fahrzeug'} · '
                      '${_formatDate(entry.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _statusIcon(status.type),
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
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
                          value: '${_formatMileage(entry.mileage)} km',
                        ),
                      ],
                    ),
                    if (entry.nextMileage != null ||
                        entry.nextDate != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Nächste Wartung',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (entry.nextMileage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Bei ${_formatMileage(entry.nextMileage!)} km'
                                '${_mileageRemainingText(entry, vehicle)}',
                              ),
                            ],
                            if (entry.nextDate != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                'Am ${_formatDate(entry.nextDate!)}'
                                '${_dateRemainingText(entry)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (entry.notes != null &&
                        entry.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes, size: 17),
                          const SizedBox(width: 6),
                          Expanded(child: Text(entry.notes!)),
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
    );
  }

  static Color _statusColor(BuildContext context, MaintenanceStatusType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case MaintenanceStatusType.overdue:
        return colorScheme.error;
      case MaintenanceStatusType.dueSoon:
        return colorScheme.tertiary;
      case MaintenanceStatusType.okay:
        return colorScheme.primary;
      case MaintenanceStatusType.noReminder:
        return colorScheme.outline;
    }
  }

  static IconData _statusIcon(MaintenanceStatusType type) {
    switch (type) {
      case MaintenanceStatusType.overdue:
        return Icons.error_outline;
      case MaintenanceStatusType.dueSoon:
        return Icons.warning_amber_rounded;
      case MaintenanceStatusType.okay:
        return Icons.check_circle_outline;
      case MaintenanceStatusType.noReminder:
        return Icons.notifications_off_outlined;
    }
  }

  static String _mileageRemainingText(
    MaintenanceEntry entry,
    Vehicle? vehicle,
  ) {
    final remaining = maintenanceKilometersRemaining(
      entry: entry,
      vehicle: vehicle,
    );

    if (remaining == null) {
      return '';
    }

    if (remaining < 0) {
      return ' · ${_formatMileage(remaining.abs())} km überfällig';
    }

    if (remaining == 0) {
      return ' · jetzt fällig';
    }

    return ' · noch ${_formatMileage(remaining)} km';
  }

  static String _dateRemainingText(MaintenanceEntry entry) {
    final remaining = maintenanceDaysRemaining(entry);

    if (remaining == null) {
      return '';
    }

    if (remaining < 0) {
      return ' · seit ${remaining.abs()} Tagen überfällig';
    }

    if (remaining == 0) {
      return ' · heute fällig';
    }

    if (remaining == 1) {
      return ' · morgen fällig';
    }

    return ' · noch $remaining Tage';
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
      case 'Luftfilter':
        return Icons.air_outlined;
      case 'Innenraumfilter':
        return Icons.airline_seat_recline_normal;
      case 'Kraftstofffilter':
        return Icons.local_gas_station_outlined;
      case 'Zündkerzen':
        return Icons.electric_bolt_outlined;
      case 'Kühlmittel':
        return Icons.ac_unit_outlined;
      case 'Getriebeöl':
        return Icons.settings_suggest_outlined;
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

  static String _formatMileage(int mileage) {
    final text = mileage.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      final positionFromEnd = text.length - index;

      buffer.write(text[index]);

      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
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
              'Erfasse deine erste Wartung und lege optional eine Erinnerung fest.',
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

class _NoVehicleView extends StatelessWidget {
  const _NoVehicleView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Lege zuerst ein Fahrzeug an, bevor du eine Wartung speicherst.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
