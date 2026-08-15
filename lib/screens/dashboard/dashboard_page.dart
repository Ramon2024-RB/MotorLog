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
    context.go('/fuel');
  }

  void _openExpenses(Vehicle vehicle) {
    context.go('/expenses');
  }

  void _openMaintenance(Vehicle vehicle) {
    context.go('/maintenance/${vehicle.id}');
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

          final statistics = calculateVehicleStatistics(fuelEntries);

          final expenseTotal = expenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          final totalCosts = statistics.totalCost + expenseTotal;

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
                  'Guten Tag, Nico',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hier siehst du alles Wichtige zu deinen Fahrzeugen.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 245,
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
                  const SizedBox(height: 12),
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

                const SizedBox(height: 30),
                const _SectionTitle(title: 'Schnellzugriff'),
                const SizedBox(height: 12),

                _PrimaryActionCard(
                  icon: Icons.local_gas_station_outlined,
                  title: 'Tanken',
                  subtitle: 'Neuen Tankvorgang erfassen',
                  onTap: () {
                    _openFuel(selectedVehicle);
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Ausgabe',
                        subtitle: 'Kosten hinzufügen',
                        onTap: () {
                          _openExpenses(selectedVehicle);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.build_outlined,
                        title: 'Wartung',
                        subtitle: 'Wartung erfassen',
                        onTap: () {
                          _openMaintenance(selectedVehicle);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const _SectionTitle(title: 'Übersicht'),
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
                const _SectionTitle(title: 'Letzte Einträge'),
                const SizedBox(height: 12),

                if (latestFuel != null)
                  _LatestEntryCard(
                    icon: Icons.local_gas_station,
                    title: latestFuel.station ?? 'Tankvorgang',
                    subtitle:
                        '${_formatDate(latestFuel.date)} · '
                        '${_formatDecimal(latestFuel.liters, 2)} Liter',
                    value: '${_formatDecimal(latestFuel.totalPrice, 2)} €',
                    onTap: () {
                      _openFuel(selectedVehicle);
                    },
                  )
                else
                  const _EmptyEntryCard(
                    icon: Icons.local_gas_station_outlined,
                    text: 'Noch kein Tankvorgang gespeichert.',
                  ),

                const SizedBox(height: 12),

                if (latestExpense != null)
                  _LatestEntryCard(
                    icon: Icons.receipt_long_outlined,
                    title: latestExpense.title,
                    subtitle:
                        '${_formatDate(latestExpense.date)} · '
                        '${latestExpense.category}',
                    value: '${_formatDecimal(latestExpense.amount, 2)} €',
                    onTap: () {
                      _openExpenses(selectedVehicle);
                    },
                  )
                else
                  const _EmptyEntryCard(
                    icon: Icons.receipt_long_outlined,
                    text: 'Noch keine Ausgabe gespeichert.',
                  ),
              ],
            ),
          );
        },
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
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colors.primary,
                    child: Icon(icon, color: colors.onPrimary, size: 30),
                  ),
                  const Spacer(),
                  if (vehicle.isDefault)
                    const Chip(
                      avatar: Icon(Icons.star, size: 16),
                      label: Text('Standard'),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${vehicle.brand} ${vehicle.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.speed, size: 19),
                  const SizedBox(width: 7),
                  Text(
                    '$mileage km',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle),
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
}

class _SmallActionCard extends StatelessWidget {
  const _SmallActionCard({
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
            const SizedBox(height: 18),
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