import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_provider.dart';
import '../../models/fuel_entry.dart';
import '../../services/fuel_entry_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.9,
  );

  int _selectedVehicleIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Vehicle> _sortVehicles(List<Vehicle> vehicles) {
    final sortedVehicles = [...vehicles];

    sortedVehicles.sort((first, second) {
      if (first.isDefault && !second.isDefault) {
        return -1;
      }

      if (!first.isDefault && second.isDefault) {
        return 1;
      }

      return first.name.toLowerCase().compareTo(
            second.name.toLowerCase(),
          );
    });

    return sortedVehicles;
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

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
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

  _DashboardStats _calculateDashboardStats(
    List<FuelEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const _DashboardStats();
    }

    final now = DateTime.now();

    final monthlyEntries = entries.where((entry) {
      return entry.date.year == now.year &&
          entry.date.month == now.month;
    }).toList();

    final monthlyFuelCosts = monthlyEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalPrice,
    );

    var monthlyDistance = 0;

    if (monthlyEntries.length >= 2) {
      final mileages = monthlyEntries
          .map((entry) => entry.mileage)
          .toList()
        ..sort();

      monthlyDistance = mileages.last - mileages.first;
    }

    return _DashboardStats(
      averageConsumption: _calculateAverageConsumption(entries),
      monthlyFuelCosts: monthlyFuelCosts,
      monthlyDistance: monthlyDistance,
      monthlyFuelEntryCount: monthlyEntries.length,
    );
  }

  double? _calculateAverageConsumption(
    List<FuelEntry> entries,
  ) {
    final fullTankEntries = entries
        .where((entry) => entry.isFullTank)
        .toList()
      ..sort(
        (a, b) => a.mileage.compareTo(b.mileage),
      );

    if (fullTankEntries.length < 2) {
      return null;
    }

    var totalDistance = 0;
    var totalLiters = 0.0;

    for (var i = 1; i < fullTankEntries.length; i++) {
      final previous = fullTankEntries[i - 1];
      final current = fullTankEntries[i];

      final distance = current.mileage - previous.mileage;

      if (distance <= 0) {
        continue;
      }

      totalDistance += distance;
      totalLiters += current.liters;
    }

    if (totalDistance == 0) {
      return null;
    }

    return totalLiters / totalDistance * 100;
  }

  String _formatDecimal(
    double value,
    int decimalPlaces,
  ) {
    return value
        .toStringAsFixed(decimalPlaces)
        .replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelEntriesAsync = ref.watch(fuelEntryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MotorLog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Benachrichtigungen',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                  ),
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

          if (_selectedVehicleIndex >= sortedVehicles.length) {
            _selectedVehicleIndex = 0;
          }

          final selectedVehicle =
              sortedVehicles[_selectedVehicleIndex];
              final allFuelEntries = fuelEntriesAsync.asData?.value ?? <FuelEntry>[];

final selectedVehicleEntries = allFuelEntries
    .where(
      (entry) => entry.vehicleId == selectedVehicle.id,
    )
    .toList()
  ..sort(
    (first, second) => first.date.compareTo(second.date),
  );

final dashboardStats = _calculateDashboardStats(
  selectedVehicleEntries,
);

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(vehicleProvider.notifier).reload();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'Guten Tag, Nico',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Hier siehst du alles Wichtige zu deinen Fahrzeugen.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 265,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: sortedVehicles.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedVehicleIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final vehicle = sortedVehicles[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        child: _VehicleCarouselCard(
                          vehicle: vehicle,
                          icon: _vehicleIcon(vehicle.vehicleType),
                          formattedMileage:
                              _formatMileage(vehicle.mileage),
                          onTap: () {
                            context.go('/vehicles');
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
                    children: List.generate(
                      sortedVehicles.length,
                      (index) {
                        final isSelected =
                            index == _selectedVehicleIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isSelected ? 22 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                : Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle(
                    title: 'Schnellaktionen',
                    actionText: 'Alle anzeigen',
                    onAction: () {},
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.local_gas_station,
                          title: 'Tanken',
                          subtitle: 'Tankvorgang erfassen',
                          onTap: () {
                            context.go('/fuel');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.receipt_long,
                          title: 'Kosten',
                          subtitle: 'Ausgabe hinzufügen',
                          onTap: () {
                            context.go('/expenses');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _SectionTitle(
                    title: 'Aktuelle Übersicht',
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
  _DashboardStatCard(
    icon: Icons.speed,
    value: dashboardStats.averageConsumption == null
        ? '–'
        : _formatDecimal(
            dashboardStats.averageConsumption!,
            1,
          ),
    unit: 'l/100 km',
    label: 'Ø Verbrauch',
  ),
  _DashboardStatCard(
    icon: Icons.euro,
    value: _formatDecimal(
      dashboardStats.monthlyFuelCosts,
      2,
    ),
    unit: '€',
    label: 'Tankkosten im Monat',
  ),
  _DashboardStatCard(
    icon: Icons.route,
    value: dashboardStats.monthlyDistance.toString(),
    unit: 'km',
    label: 'Diesen Monat',
  ),
  _DashboardStatCard(
    icon: Icons.local_gas_station_outlined,
              value: dashboardStats.monthlyFuelEntryCount.toString(),
               unit: '',
                label: 'Tankvorgänge',
                ),
                ],
                  ),
                ),

                const SizedBox(height: 28),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const _SectionTitle(
                    title: 'Nächste Aufgaben',
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _UpcomingTaskCard(
                    icon: Icons.build_outlined,
                    title: 'Wartungsplan einrichten',
                    subtitle:
                        'Lege Ölwechsel, TÜV und weitere Termine für ${selectedVehicle.name} an.',
                    actionText: 'Später einrichten',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    this.averageConsumption,
    this.monthlyFuelCosts = 0,
    this.monthlyDistance = 0,
    this.monthlyFuelEntryCount = 0,
  });

  final double? averageConsumption;
  final double monthlyFuelCosts;
  final int monthlyDistance;
  final int monthlyFuelEntryCount;
}

class _VehicleCarouselCard extends StatelessWidget {
  const _VehicleCarouselCard({
    required this.vehicle,
    required this.icon,
    required this.formattedMileage,
    required this.onTap,
  });

  final Vehicle vehicle;
  final IconData icon;
  final String formattedMileage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      icon,
                      size: 31,
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
              const Spacer(),
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                '${vehicle.brand} ${vehicle.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  _VehicleDetailChip(
                    icon: Icons.category_outlined,
                    label: vehicle.vehicleType,
                  ),
                  const SizedBox(width: 8),
                  _VehicleDetailChip(
                    icon: Icons.local_gas_station_outlined,
                    label: vehicle.fuelType,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 19,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '$formattedMileage km',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

class _VehicleDetailChip extends StatelessWidget {
  const _VehicleDetailChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 31,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
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
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
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

class _UpcomingTaskCard extends StatelessWidget {
  const _UpcomingTaskCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(icon),
            ),
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
                  const SizedBox(height: 5),
                  Text(subtitle),
                  const SizedBox(height: 9),
                  TextButton(
                    onPressed: onTap,
                    child: Text(actionText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionText!),
          ),
      ],
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({
    required this.onAddVehicle,
  });

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
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Willkommen bei MotorLog',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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