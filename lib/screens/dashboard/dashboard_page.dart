import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/expense.dart';
import '../../models/fuel_entry.dart';
import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';
import '../../services/expense_provider.dart';
import '../../services/fuel_entry_provider.dart';
import '../../services/maintenance_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../utils/maintenance_status_calculator.dart';
import '../../utils/vehicle_statistics_calculator.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _selectedVehicleId;

  List<Vehicle> _sortVehicles(List<Vehicle> vehicles) {
    final sorted = [...vehicles];

    sorted.sort((a, b) {
      if (a.isDefault && !b.isDefault) {
        return -1;
      }

      if (!a.isDefault && b.isDefault) {
        return 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted;
  }

  Vehicle _getSelectedVehicle(List<Vehicle> vehicles) {
    final sorted = _sortVehicles(vehicles);

    if (_selectedVehicleId != null) {
      for (final vehicle in sorted) {
        if (vehicle.id == _selectedVehicleId) {
          return vehicle;
        }
      }
    }

    return sorted.first;
  }

  String _formatMileage(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;

      buffer.write(text[i]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  String _formatDecimal(double value, int digits) {
    return value.toStringAsFixed(digits).replaceAll('.', ',');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  IconData _vehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'camper':
        return Icons.airport_shuttle_outlined;
      case 'motorrad':
        return Icons.two_wheeler;
      case 'transporter':
        return Icons.local_shipping_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }

  void _openFuel(Vehicle vehicle) {
    context.go(
      Uri(path: '/fuel', queryParameters: {'vehicleId': vehicle.id}).toString(),
    );
  }

  void _openExpenses(Vehicle vehicle) {
    context.go(
      Uri(
        path: '/expenses',
        queryParameters: {'vehicleId': vehicle.id},
      ).toString(),
    );
  }

  void _openMaintenance(Vehicle vehicle) {
    context.go('/maintenance/${vehicle.id}');
  }

  void _openTires(Vehicle vehicle) {
    context.go('/tires/${vehicle.id}');
  }

  void _openDocuments(Vehicle vehicle) {
    context.go('/documents/${vehicle.id}');
  }

  void _openSettings() {
    context.go('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelAsync = ref.watch(fuelEntryProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final maintenanceAsync = ref.watch(maintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MotorLog',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Profil und Einstellungen',
            onPressed: _openSettings,
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 16),
                  const Text(
                    'Das Dashboard konnte nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(vehicleProvider.notifier).reload();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _EmptyDashboard(
              onAddVehicle: () {
                context.go('/vehicles');
              },
            );
          }

          final sortedVehicles = _sortVehicles(vehicles);
          final selectedVehicle = _getSelectedVehicle(vehicles);

          final allFuelEntries = fuelAsync.asData?.value ?? <FuelEntry>[];

          final fuelEntries =
              allFuelEntries
                  .where((entry) => entry.vehicleId == selectedVehicle.id)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final expenses =
              allExpenses
                  .where((entry) => entry.vehicleId == selectedVehicle.id)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

          final allMaintenance =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final maintenance = allMaintenance
              .where((entry) => entry.vehicleId == selectedVehicle.id)
              .toList();

          final upcomingMaintenance = maintenance
              .where(
                (entry) => entry.nextDate != null || entry.nextMileage != null,
              )
              .toList();

          upcomingMaintenance.sort((a, b) {
            final firstStatus = calculateMaintenanceStatus(
              entry: a,
              vehicle: selectedVehicle,
            );

            final secondStatus = calculateMaintenanceStatus(
              entry: b,
              vehicle: selectedVehicle,
            );

            final priorityComparison = firstStatus.priority.compareTo(
              secondStatus.priority,
            );

            if (priorityComparison != 0) {
              return priorityComparison;
            }

            final firstDate =
                a.nextDate ??
                DateTime.fromMillisecondsSinceEpoch(8640000000000000);

            final secondDate =
                b.nextDate ??
                DateTime.fromMillisecondsSinceEpoch(8640000000000000);

            final dateComparison = firstDate.compareTo(secondDate);

            if (dateComparison != 0) {
              return dateComparison;
            }

            final firstMileage = a.nextMileage ?? 2147483647;

            final secondMileage = b.nextMileage ?? 2147483647;

            return firstMileage.compareTo(secondMileage);
          });

          final statistics = calculateVehicleStatistics(
            fuelEntries: fuelEntries,
            expenses: expenses,
            maintenanceEntries: maintenance,
          );

          final totalCosts = statistics.totalVehicleCost;

          final latestFuel = fuelEntries.isEmpty ? null : fuelEntries.last;

          final latestExpense = expenses.isEmpty ? null : expenses.last;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(vehicleProvider.notifier).reload(),
                ref.read(fuelEntryProvider.notifier).reload(),
                ref.read(expenseProvider.notifier).reload(),
                ref.read(maintenanceProvider.notifier).reload(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(
                  'Deine Garage',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Alles im Blick. Jede Fahrt zählt.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 216,
                  child: PageView.builder(
                    controller: PageController(
                      viewportFraction: sortedVehicles.length > 1 ? 0.94 : 1.0,
                      initialPage: sortedVehicles.indexWhere(
                        (vehicle) => vehicle.id == selectedVehicle.id,
                      ),
                    ),
                    itemCount: sortedVehicles.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedVehicleId = sortedVehicles[index].id;
                      });
                    },
                    itemBuilder: (context, index) {
                      final vehicle = sortedVehicles[index];

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < sortedVehicles.length - 1 ? 10 : 0,
                        ),
                        child: _VehicleCard(
                          vehicle: vehicle,
                          icon: _vehicleIcon(vehicle.vehicleType),
                          mileage: _formatMileage(vehicle.mileage),
                          onTap: () {
                            context.go('/vehicles/${vehicle.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),

                if (sortedVehicles.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(sortedVehicles.length, (index) {
                      final isSelected =
                          sortedVehicles[index].id == selectedVehicle.id;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isSelected ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: 24),
                _DashboardStatusStrip(
                  upcoming: upcomingMaintenance,
                  vehicle: selectedVehicle,
                  onTap: () => _openMaintenance(selectedVehicle),
                ),
                const SizedBox(height: 28),
                const _SectionTitle(title: 'Direkt starten'),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.local_gas_station_outlined,
                        title: 'Tanken',
                        subtitle: 'Neuer Eintrag',
                        onTap: () {
                          _openFuel(selectedVehicle);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.build_outlined,
                        title: 'Wartung',
                        subtitle: 'Service & Pflege',
                        onTap: () {
                          _openMaintenance(selectedVehicle);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.tire_repair,
                        title: 'Reifen',
                        subtitle: 'Reifensätze',
                        onTap: () {
                          _openTires(selectedVehicle);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.description_outlined,
                        title: 'Dokumente',
                        subtitle: 'Fahrzeugakte',
                        onTap: () {
                          _openDocuments(selectedVehicle);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'Anstehende Wartungen'),
                    ),
                    TextButton(
                      onPressed: () {
                        _openMaintenance(selectedVehicle);
                      },
                      child: const Text('Alle'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (upcomingMaintenance.isEmpty)
                  _NoUpcomingMaintenanceCard(
                    onTap: () {
                      _openMaintenance(selectedVehicle);
                    },
                  )
                else
                  ...upcomingMaintenance.take(3).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UpcomingMaintenanceCard(
                        entry: entry,
                        vehicle: selectedVehicle,
                        onTap: () {
                          _openMaintenance(selectedVehicle);
                        },
                      ),
                    );
                  }),

                const SizedBox(height: 18),

                const _SectionTitle(title: 'Performance & Kosten'),

                const SizedBox(height: 12),

                _StatRow(
                  left: _StatData(
                    icon: Icons.speed,
                    title: 'Ø Verbrauch',
                    value: statistics.averageConsumption <= 0
                        ? '–'
                        : '${_formatDecimal(statistics.averageConsumption, 1)} l/100 km',
                  ),
                  right: _StatData(
                    icon: Icons.euro,
                    title: 'Gesamtkosten',
                    value: '${_formatDecimal(totalCosts, 2)} €',
                  ),
                ),

                const SizedBox(height: 12),

                _StatRow(
                  left: _StatData(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Tankvorgänge',
                    value: statistics.refuels.toString(),
                  ),
                  right: _StatData(
                    icon: Icons.receipt_long_outlined,
                    title: 'Ausgaben',
                    value: expenses.length.toString(),
                  ),
                ),

                const SizedBox(height: 12),

                _StatRow(
                  left: _StatData(
                    icon: Icons.build_outlined,
                    title: 'Wartungen',
                    value: maintenance.length.toString(),
                  ),
                  right: _StatData(
                    icon: Icons.route_outlined,
                    title: 'Ausgewertet',
                    value: '${_formatMileage(statistics.totalDistance)} km',
                  ),
                ),

                const SizedBox(height: 30),

                const _SectionTitle(title: 'Aktivitäten'),

                const SizedBox(height: 12),

                if (latestFuel == null && latestExpense == null)
                  const _EmptyEntryCard(
                    icon: Icons.history_rounded,
                    text: 'Noch keine Aktivitäten für dieses Fahrzeug.',
                  )
                else ...[
                  if (latestFuel != null &&
                      (latestExpense == null ||
                          !latestFuel.date.isBefore(latestExpense.date))) ...[
                    _LatestEntryCard(
                      icon: Icons.local_gas_station,
                      title: latestFuel.station ?? 'Tankvorgang',
                      subtitle:
                          '${_formatDate(latestFuel.date)} · '
                          '${_formatDecimal(latestFuel.liters, 2)} Liter',
                      value: '${_formatDecimal(latestFuel.totalPrice, 2)} €',
                      onTap: () => _openFuel(selectedVehicle),
                    ),
                    if (latestExpense != null) const SizedBox(height: 12),
                  ],
                  if (latestExpense != null)
                    _LatestEntryCard(
                      icon: Icons.receipt_long_outlined,
                      title: latestExpense.title,
                      subtitle:
                          '${_formatDate(latestExpense.date)} · '
                          '${latestExpense.category}',
                      value: '${_formatDecimal(latestExpense.amount, 2)} €',
                      onTap: () => _openExpenses(selectedVehicle),
                    ),
                  if (latestFuel != null &&
                      latestExpense != null &&
                      latestFuel.date.isBefore(latestExpense.date)) ...[
                    const SizedBox(height: 12),
                    _LatestEntryCard(
                      icon: Icons.local_gas_station,
                      title: latestFuel.station ?? 'Tankvorgang',
                      subtitle:
                          '${_formatDate(latestFuel.date)} · '
                          '${_formatDecimal(latestFuel.liters, 2)} Liter',
                      value: '${_formatDecimal(latestFuel.totalPrice, 2)} €',
                      onTap: () => _openFuel(selectedVehicle),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardStatusStrip extends StatelessWidget {
  const _DashboardStatusStrip({
    required this.upcoming,
    required this.vehicle,
    required this.onTap,
  });

  final List<MaintenanceEntry> upcoming;
  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final urgent = upcoming.where((entry) {
      final type = calculateMaintenanceStatus(
        entry: entry,
        vehicle: vehicle,
      ).type;
      return type == MaintenanceStatusType.overdue ||
          type == MaintenanceStatusType.dueSoon;
    }).length;
    final isUrgent = urgent > 0;
    final accent = isUrgent ? colors.error : colors.primary;

    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Icon(
                isUrgent
                    ? Icons.warning_amber_rounded
                    : Icons.verified_outlined,
                color: accent,
                size: 27,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrgent
                          ? '$urgent Wartung${urgent == 1 ? '' : 'en'} bald fällig'
                          : 'Fahrzeugstatus',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isUrgent
                          ? 'Wichtige Termine und Intervalle prüfen'
                          : upcoming.isEmpty
                          ? 'Keine Wartungserinnerungen eingerichtet'
                          : '${upcoming.length} Wartungserinnerung${upcoming.length == 1 ? '' : 'en'} hinterlegt',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingMaintenanceCard extends StatelessWidget {
  const _UpcomingMaintenanceCard({
    required this.entry,
    required this.vehicle,
    required this.onTap,
  });

  final MaintenanceEntry entry;
  final Vehicle vehicle;
  final VoidCallback onTap;

  String _formatMileage(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < text.length; index++) {
      final remaining = text.length - index;

      buffer.write(text[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  String _reminderText() {
    final parts = <String>[];

    final days = maintenanceDaysRemaining(entry);

    if (days != null) {
      if (days < 0) {
        parts.add('seit ${days.abs()} Tagen');
      } else if (days == 0) {
        parts.add('heute');
      } else if (days == 1) {
        parts.add('morgen');
      } else if (days <= 30) {
        parts.add('in $days Tagen');
      } else {
        parts.add(_formatDate(entry.nextDate!));
      }
    }

    final remainingKilometers = maintenanceKilometersRemaining(
      entry: entry,
      vehicle: vehicle,
    );

    if (remainingKilometers != null) {
      if (remainingKilometers < 0) {
        parts.add(
          '${_formatMileage(remainingKilometers.abs())} km überschritten',
        );
      } else if (remainingKilometers == 0) {
        parts.add('Kilometerstand erreicht');
      } else {
        parts.add('noch ${_formatMileage(remainingKilometers)} km');
      }
    }

    return parts.join(' · ');
  }

  Color _statusColor(BuildContext context, MaintenanceStatusType type) {
    final colors = Theme.of(context).colorScheme;

    switch (type) {
      case MaintenanceStatusType.overdue:
        return colors.error;
      case MaintenanceStatusType.dueSoon:
        return colors.tertiary;
      case MaintenanceStatusType.okay:
        return colors.primary;
      case MaintenanceStatusType.noReminder:
        return colors.outline;
    }
  }

  IconData _statusIcon(MaintenanceStatusType type) {
    switch (type) {
      case MaintenanceStatusType.overdue:
        return Icons.error_outline;
      case MaintenanceStatusType.dueSoon:
        return Icons.warning_amber_rounded;
      case MaintenanceStatusType.okay:
        return Icons.event_available_outlined;
      case MaintenanceStatusType.noReminder:
        return Icons.notifications_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = calculateMaintenanceStatus(entry: entry, vehicle: vehicle);

    final color = _statusColor(context, status.type);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_statusIcon(status.type), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _reminderText(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoUpcomingMaintenanceCard extends StatelessWidget {
  const _NoUpcomingMaintenanceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.notifications_none_outlined,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keine Fälligkeiten',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Für dieses Fahrzeug sind noch keine Wartungserinnerungen hinterlegt.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.icon,
    required this.mileage,
    required this.onTap,
  });

  final Vehicle vehicle;
  final IconData icon;
  final String mileage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const dark = Color(0xFF111827);
    const graphite = Color(0xFF263448);

    return Container(
      margin: const EdgeInsets.only(right: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [graphite, dark],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -35,
                top: -52,
                child: Icon(
                  icon,
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(icon, color: Colors.white, size: 25),
                        ),
                        const Spacer(),
                        if (vehicle.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE6B967,
                              ).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Color(0xFFE6B967),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'STANDARD',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE6B967),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFC5CEDB)),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        const Icon(
                          Icons.speed_rounded,
                          size: 18,
                          color: Color(0xFFE6B967),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$mileage km',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 79,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(icon, color: colors.primary, size: 22),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.left, required this.right});

  final _StatData left;
  final _StatData right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _StatCard(data: left)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(data: right)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestEntryCard extends StatelessWidget {
  const _LatestEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEntryCard extends StatelessWidget {
  const _EmptyEntryCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Willkommen bei MotorLog',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lege dein erstes Fahrzeug an und behalte Tanken, Kosten und Wartungen im Blick.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Fahrzeug hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
