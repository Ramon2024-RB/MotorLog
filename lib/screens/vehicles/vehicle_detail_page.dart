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
import '../../services/premium_provider.dart';
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

  void _openTires(BuildContext context, Vehicle vehicle) {
    context.go('/tires/${vehicle.id}');
  }

  void _openDocuments(BuildContext context, Vehicle vehicle) {
    context.go('/documents/${vehicle.id}');
  }

  void _openStatistics(BuildContext context, Vehicle vehicle) {
    context.go('/statistics/${vehicle.id}');
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.workspace_premium_outlined),
          title: const Text('Premium-Funktion'),
          content: const Text(
            'Dokumente und Fahrzeugunterlagen sind mit '
            'MotorLog Premium verfügbar.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Später'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/premium');
              },
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Premium entdecken'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelEntriesAsync = ref.watch(fuelEntryProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final maintenanceAsync = ref.watch(maintenanceProvider);
    final premiumAsync = ref.watch(premiumProvider);

    final isPremium = premiumAsync.value ?? false;

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

          // -------------------------------------------------------------------
          // Tankvorgänge des Fahrzeugs
          // -------------------------------------------------------------------

          final allFuelEntries =
              fuelEntriesAsync.asData?.value ?? <FuelEntry>[];

          final vehicleFuelEntries =
              allFuelEntries
                  .where((entry) => entry.vehicleId == vehicle.id)
                  .toList()
                ..sort((first, second) => first.date.compareTo(second.date));

          // -------------------------------------------------------------------
          // Sonstige Kosten des Fahrzeugs
          // -------------------------------------------------------------------

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final vehicleExpenses = allExpenses
              .where((expense) => expense.vehicleId == vehicle.id)
              .toList();

          // -------------------------------------------------------------------
          // Wartungen des Fahrzeugs
          // -------------------------------------------------------------------

          final allMaintenanceEntries =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final vehicleMaintenanceEntries = allMaintenanceEntries
              .where((entry) => entry.vehicleId == vehicle.id)
              .toList();

          // -------------------------------------------------------------------
          // Zentrale Fahrzeugstatistik
          // -------------------------------------------------------------------

          final vehicleStatistics = calculateVehicleStatistics(
            fuelEntries: vehicleFuelEntries,
            expenses: vehicleExpenses,
            maintenanceEntries: vehicleMaintenanceEntries,
          );

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
                ref.read(premiumProvider.notifier).reload(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              children: [
                _VehicleHeaderCard(
                  vehicle: vehicle,
                  formattedMileage: _formatMileage(vehicle.mileage),
                ),

                const SizedBox(height: 22),

                const _SectionTitle(title: 'Übersicht'),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
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
                      value:
                          '${_formatDecimal(vehicleStatistics.totalVehicleCost, 2)} €',
                    ),
                    _DetailTile(
                      icon: Icons.build_outlined,
                      title: 'Wartungen',
                      value: vehicleStatistics.maintenanceEntries.toString(),
                    ),
                    _DetailTile(
                      icon: Icons.local_gas_station_outlined,
                      title: 'Tankvorgänge',
                      value: vehicleStatistics.refuels.toString(),
                    ),
                    _DetailTile(
                      icon: Icons.route_outlined,
                      title: 'Ausgewertet',
                      value:
                          '${_formatMileage(vehicleStatistics.totalDistance)} km',
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const _SectionTitle(title: 'Letzter Tankvorgang'),

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
                    formattedMileage: _formatMileage(latestFuelEntry.mileage),
                    onTap: () {
                      _openFuel(context, vehicle);
                    },
                  ),

                const SizedBox(height: 22),

                const _SectionTitle(title: 'Fahrzeugakte'),

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

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'Kosten',
                  subtitle:
                      '${vehicleStatistics.expenses} Ausgaben gespeichert',
                  onTap: () {
                    _openExpenses(context, vehicle);
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.build_outlined,
                  title: 'Wartungen',
                  subtitle:
                      '${vehicleStatistics.maintenanceEntries} '
                      'Wartungen gespeichert',
                  onTap: () {
                    _openMaintenance(context, vehicle);
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.tire_repair,
                  title: 'Reifen',
                  subtitle: 'Reifensätze und Reifenwechsel',
                  onTap: () {
                    _openTires(context, vehicle);
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.description_outlined,
                  title: 'Dokumente',
                  subtitle: isPremium
                      ? 'Rechnungen und Fahrzeugunterlagen'
                      : 'Premium-Funktion',
                  isPremiumLocked: !isPremium,
                  onTap: () {
                    if (isPremium) {
                      _openDocuments(context, vehicle);
                      return;
                    }

                    _showPremiumDialog(context);
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.query_stats,
                  title: 'Statistiken',
                  subtitle: 'Verbrauch, Kosten und Auswertungen',
                  onTap: () {
                    _openStatistics(context, vehicle);
                  },
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
  const _VehicleHeaderCard({
    required this.vehicle,
    required this.formattedMileage,
  });

  final Vehicle vehicle;
  final String formattedMileage;

  IconData _vehicleIcon() {
    switch (vehicle.vehicleType.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    _vehicleIcon(),
                    size: 27,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const Spacer(),
                if (vehicle.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
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
                          size: 15,
                          color: colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Standard',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              vehicle.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 3),

            Text(
              '${vehicle.brand} ${vehicle.model}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: vehicle.vehicleType,
                ),
                _InfoChip(
                  icon: Icons.local_gas_station_outlined,
                  label: vehicle.fuelType,
                ),
                _InfoChip(icon: Icons.speed, label: '$formattedMileage km'),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: vehicle.year.toString(),
                ),
                if (vehicle.licensePlate != null &&
                    vehicle.licensePlate!.trim().isNotEmpty)
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
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
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
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

class _LatestFuelCard extends StatelessWidget {
  const _LatestFuelCard({
    required this.entry,
    required this.formattedDate,
    required this.formattedLiters,
    required this.formattedPrice,
    required this.formattedMileage,
    required this.onTap,
  });

  final FuelEntry entry;
  final String formattedDate;
  final String formattedLiters;
  final String formattedPrice;
  final String formattedMileage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.local_gas_station,
                  color: colorScheme.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

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
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 7),

                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
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
                          '$formattedMileage km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
              'Für dieses Fahrzeug wurde noch kein '
              'Tankvorgang gespeichert.',
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
    this.isPremiumLocked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPremiumLocked;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        if (isPremiumLocked) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 12,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

              const SizedBox(width: 6),

              Icon(
                isPremiumLocked ? Icons.lock_outline : Icons.chevron_right,
                size: 21,
                color: isPremiumLocked ? colorScheme.primary : null,
              ),
            ],
          ),
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
