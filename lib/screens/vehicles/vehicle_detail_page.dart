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
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_vehicle_dialog.dart';

class VehicleDetailPage extends ConsumerWidget {
  const VehicleDetailPage({super.key, required this.vehicleId});

  final String vehicleId;

  Vehicle? _findVehicle(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId) {
        return vehicle;
      }
    }

    return null;
  }

  String _formatDecimal(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }

  String _formatMileage(int mileage) {
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  void _openFuel(BuildContext context, Vehicle vehicle) {
    context.go(
      Uri(path: '/fuel', queryParameters: {'vehicleId': vehicle.id}).toString(),
    );
  }

  void _openExpenses(BuildContext context, Vehicle vehicle) {
    context.go(
      Uri(
        path: '/expenses',
        queryParameters: {'vehicleId': vehicle.id},
      ).toString(),
    );
  }

  void _openMaintenance(BuildContext context, Vehicle vehicle) {
    context.go('/maintenance/${vehicle.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelEntriesAsync = ref.watch(fuelEntryProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final maintenanceAsync = ref.watch(maintenanceProvider);

    final loadedVehicles = vehiclesAsync.asData?.value ?? <Vehicle>[];
    final selectedVehicle = _findVehicle(loadedVehicles);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fahrzeugdetails',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Fahrzeug bearbeiten',
            icon: const Icon(Icons.edit_outlined),
            onPressed: selectedVehicle == null
                ? null
                : () async {
                    await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AddVehicleDialog(vehicle: selectedVehicle);
                      },
                    );
                  },
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
              child: Text(
                'Fahrzeug konnte nicht geladen werden.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (vehicles) {
          final vehicle = _findVehicle(vehicles);

          if (vehicle == null) {
            return const Center(
              child: Text('Das Fahrzeug wurde nicht gefunden.'),
            );
          }

          final allFuelEntries =
              fuelEntriesAsync.asData?.value ?? <FuelEntry>[];

          final vehicleFuelEntries =
              allFuelEntries
                  .where((entry) => entry.vehicleId == vehicle.id)
                  .toList()
                ..sort((first, second) => first.date.compareTo(second.date));

          final vehicleStatistics = calculateVehicleStatistics(
            vehicleFuelEntries,
          );

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final vehicleExpenses = allExpenses
              .where((expense) => expense.vehicleId == vehicle.id)
              .toList();

          final totalExpenses = vehicleExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          final totalVehicleCosts = vehicleStatistics.totalCost + totalExpenses;

          final allMaintenanceEntries =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final vehicleMaintenanceEntries = allMaintenanceEntries
              .where((entry) => entry.vehicleId == vehicle.id)
              .toList();

          final latestFuelEntry = vehicleFuelEntries.isEmpty
              ? null
              : vehicleFuelEntries.last;

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _VehicleHeaderCard(vehicle: vehicle),
                const SizedBox(height: 24),

                Text(
                  'Übersicht',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _DetailTile(
                      icon: Icons.speed,
                      title: 'Verbrauch',
                      value: vehicleStatistics.averageConsumption <= 0
                          ? '–'
                          : '${_formatDecimal(vehicleStatistics.averageConsumption, 1)} l/100 km',
                    ),
                    _DetailTile(
                      icon: Icons.euro,
                      title: 'Gesamtkosten',
                      value: '${_formatDecimal(totalVehicleCosts, 2)} €',
                    ),
                    _DetailTile(
                      icon: Icons.build_outlined,
                      title: 'Wartungen',
                      value: vehicleMaintenanceEntries.length.toString(),
                    ),
                    _DetailTile(
                      icon: Icons.local_gas_station_outlined,
                      title: 'Tankvorgänge',
                      value: vehicleStatistics.refuels.toString(),
                    ),
                    _DetailTile(
                      icon: Icons.route,
                      title: 'Ausgewertete Strecke',
                      value:
                          '${_formatMileage(vehicleStatistics.totalDistance)} km',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Letzter Tankvorgang',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (latestFuelEntry == null)
                  const _EmptyFuelCard()
                else
                  _LatestFuelCard(
                    entry: latestFuelEntry,
                    formattedDate: _formatDate(latestFuelEntry.date),
                    formattedLiters: _formatDecimal(latestFuelEntry.liters, 2),
                    formattedPrice: _formatDecimal(
                      latestFuelEntry.totalPrice,
                      2,
                    ),
                    onTap: () {
                      _openFuel(context, vehicle);
                    },
                  ),

                const SizedBox(height: 24),

                Text(
                  'Fahrzeugakte',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.local_gas_station_outlined,
                  title: 'Tankvorgänge',
                  subtitle:
                      '${vehicleStatistics.refuels} Tankvorgänge gespeichert',
                  onTap: () {
                    _openFuel(context, vehicle);
                  },
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Kosten',
                  subtitle: '${vehicleExpenses.length} Ausgaben gespeichert',
                  onTap: () {
                    _openExpenses(context, vehicle);
                  },
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.build_outlined,
                  title: 'Wartungen',
                  subtitle:
                      '${vehicleMaintenanceEntries.length} Wartungen gespeichert',
                  onTap: () {
                    _openMaintenance(context, vehicle);
                  },
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.tire_repair,
                  title: 'Reifen',
                  subtitle: 'Reifensätze und Reifenwechsel',
                  onTap: () {},
                ),

                const SizedBox(height: 12),

                _MenuCard(
                  icon: Icons.description_outlined,
                  title: 'Dokumente',
                  subtitle: 'Rechnungen und Fahrzeugunterlagen',
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehicleHeaderCard extends StatelessWidget {
  const _VehicleHeaderCard({required this.vehicle});

  final Vehicle vehicle;

  IconData _vehicleIcon() {
    switch (vehicle.vehicleType.toLowerCase()) {
      case 'camper':
        return Icons.airport_shuttle;
      case 'motorrad':
        return Icons.two_wheeler;
      case 'transporter':
        return Icons.local_shipping_outlined;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    _vehicleIcon(),
                    size: 32,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const Spacer(),
                if (vehicle.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Standard',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              vehicle.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              '${vehicle.brand} ${vehicle.model}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: vehicle.vehicleType,
                ),
                _InfoChip(
                  icon: Icons.local_gas_station_outlined,
                  label: vehicle.fuelType,
                ),
                _InfoChip(icon: Icons.speed, label: '${vehicle.mileage} km'),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: vehicle.year.toString(),
                ),
                if (vehicle.licensePlate != null &&
                    vehicle.licensePlate!.isNotEmpty)
                  _InfoChip(
                    icon: Icons.badge_outlined,
                    label: vehicle.licensePlate!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const Spacer(),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestFuelCard extends StatelessWidget {
  const _LatestFuelCard({
    required this.entry,
    required this.formattedDate,
    required this.formattedLiters,
    required this.formattedPrice,
    required this.onTap,
  });

  final FuelEntry entry;
  final String formattedDate;
  final String formattedLiters;
  final String formattedPrice;
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
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.local_gas_station,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.station ?? 'Tankvorgang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          '$formattedLiters Liter',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$formattedPrice €',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${entry.mileage} km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
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

class _EmptyFuelCard extends StatelessWidget {
  const _EmptyFuelCard();

  @override
  Widget build(BuildContext context) {
    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: const Row(
        children: [
          Icon(Icons.local_gas_station_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Für dieses Fahrzeug wurde noch kein Tankvorgang gespeichert.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
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
    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
