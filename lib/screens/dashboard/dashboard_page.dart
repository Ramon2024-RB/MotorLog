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
import '../../widgets/dashboard/dashboard_maintenance_card.dart';
import '../../widgets/dashboard/dashboard_quick_actions.dart';
import '../expenses/expenses_page.dart';
import '../maintenance/maintenance_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() {
    return _DashboardPageState();
  }
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

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

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
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

  String _formatDecimal(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
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

  void _openFuelPage(BuildContext context) {
    context.go('/fuel');
  }

  void _openExpensePage(BuildContext context) {
    context.go('/expenses');
  }

  void _openMaintenancePage(BuildContext context, Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return MaintenancePage(vehicleId: vehicle.id);
        },
      ),
    );
  }

  void _showNewEntrySheet(BuildContext context, Vehicle vehicle) {
    final pageContext = context;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Neuer Eintrag',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Was möchtest du hinzufügen?',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _NewEntryTile(
                icon: Icons.local_gas_station_outlined,
                title: 'Tankvorgang',
                subtitle: 'Eine neue Tankung erfassen',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openFuelPage(pageContext);
                },
              ),
              const SizedBox(height: 10),
              _NewEntryTile(
                icon: Icons.receipt_long_outlined,
                title: 'Ausgabe',
                subtitle: 'Neue Fahrzeugkosten erfassen',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openExpensePage(pageContext);
                },
              ),
              const SizedBox(height: 10),
              _NewEntryTile(
                icon: Icons.build_outlined,
                title: 'Wartung',
                subtitle: 'Eine Wartung oder Reparatur erfassen',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openMaintenancePage(pageContext, vehicle);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelEntriesAsync = ref.watch(fuelEntryProvider);
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  const SizedBox(height: 12),
                  Text(error.toString(), textAlign: TextAlign.center),
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

          final selectedVehicle = sortedVehicles[_selectedVehicleIndex];

          final allFuelEntries =
              fuelEntriesAsync.asData?.value ?? <FuelEntry>[];

          final selectedVehicleFuelEntries =
              allFuelEntries
                  .where((entry) => entry.vehicleId == selectedVehicle.id)
                  .toList()
                ..sort((first, second) => first.date.compareTo(second.date));

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final selectedVehicleExpenses =
              allExpenses
                  .where((expense) => expense.vehicleId == selectedVehicle.id)
                  .toList()
                ..sort((first, second) => first.date.compareTo(second.date));

          final allMaintenanceEntries =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final selectedVehicleMaintenanceEntries = allMaintenanceEntries
              .where((entry) => entry.vehicleId == selectedVehicle.id)
              .toList();

          final vehicleStatistics = calculateVehicleStatistics(
            selectedVehicleFuelEntries,
          );

          final latestFuelEntry = selectedVehicleFuelEntries.isEmpty
              ? null
              : selectedVehicleFuelEntries.last;

          final latestExpense = selectedVehicleExpenses.isEmpty
              ? null
              : selectedVehicleExpenses.last;

          final totalExpenses = selectedVehicleExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          final totalVehicleCosts = vehicleStatistics.totalCost + totalExpenses;

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
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'Guten Tag, Nico',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _VehicleCarouselCard(
                          vehicle: vehicle,
                          icon: _vehicleIcon(vehicle.vehicleType),
                          formattedMileage: _formatMileage(vehicle.mileage),
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
                      final isSelected = index == _selectedVehicleIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: isSelected ? 22 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
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
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle(title: 'Schnellzugriff'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DashboardQuickActions(
                    onFuelTap: () {
                      _openFuelPage(context);
                    },
                    onExpenseTap: () {
                      _openExpensePage(context);
                    },
                    onMaintenanceTap: () {
                      _openMaintenancePage(context, selectedVehicle);
                    },
                    onNewEntryTap: () {
                      _showNewEntrySheet(context, selectedVehicle);
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle(title: 'Wartungsstatus'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DashboardMaintenanceCard(
                    vehicle: selectedVehicle,
                    entries: selectedVehicleMaintenanceEntries,
                    onTap: () {
                      _openMaintenancePage(context, selectedVehicle);
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle(title: 'Aktuelle Übersicht'),
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
                    childAspectRatio: 1.22,
                    children: [
                      _DashboardStatCard(
                        icon: Icons.speed,
                        value: vehicleStatistics.averageConsumption <= 0
                            ? '–'
                            : _formatDecimal(
                                vehicleStatistics.averageConsumption,
                                1,
                              ),
                        unit: 'l/100 km',
                        label: 'Ø Verbrauch',
                      ),
                      _DashboardStatCard(
                        icon: Icons.euro,
                        value: _formatDecimal(totalVehicleCosts, 2),
                        unit: '€',
                        label: 'Gesamtkosten',
                      ),
                      _DashboardStatCard(
                        icon: Icons.local_gas_station_outlined,
                        value: vehicleStatistics.refuels.toString(),
                        unit: '',
                        label: 'Tankvorgänge',
                      ),
                      _DashboardStatCard(
                        icon: Icons.receipt_long_outlined,
                        value: selectedVehicleExpenses.length.toString(),
                        unit: '',
                        label: 'Ausgaben',
                      ),
                      _DashboardStatCard(
                        icon: Icons.build_outlined,
                        value: selectedVehicleMaintenanceEntries.length
                            .toString(),
                        unit: '',
                        label: 'Wartungen',
                      ),
                      _DashboardStatCard(
                        icon: Icons.route,
                        value: _formatMileage(vehicleStatistics.totalDistance),
                        unit: 'km',
                        label: 'Ausgewertet',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle(title: 'Letzte Einträge'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (latestFuelEntry == null)
                        const _NoLatestFuelCard()
                      else
                        _LatestFuelCard(
                          entry: latestFuelEntry,
                          formatDate: _formatDate,
                          formatDecimal: _formatDecimal,
                          onTap: () {
                            _openFuelPage(context);
                          },
                        ),
                      const SizedBox(height: 12),
                      if (latestExpense == null)
                        const _NoLatestExpenseCard()
                      else
                        _LatestExpenseCard(
                          expense: latestExpense,
                          formattedDate: _formatDate(latestExpense.date),
                          formattedAmount: _formatDecimal(
                            latestExpense.amount,
                            2,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) {
                                  return ExpensesPage(
                                    vehicleId: selectedVehicle.id,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                    ],
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

class _NewEntryTile extends StatelessWidget {
  const _NewEntryTile({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
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
                    radius: 29,
                    backgroundColor: colorScheme.primary,
                    child: Icon(icon, size: 31, color: colorScheme.onPrimary),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _VehicleDetailChip(
                    icon: Icons.category_outlined,
                    label: vehicle.vehicleType,
                  ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
  const _VehicleDetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.65),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
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

class _LatestFuelCard extends StatelessWidget {
  const _LatestFuelCard({
    required this.entry,
    required this.formatDate,
    required this.formatDecimal,
    required this.onTap,
  });

  final FuelEntry entry;
  final String Function(DateTime) formatDate;
  final String Function(double, int) formatDecimal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
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
                      formatDate(entry.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          '${formatDecimal(entry.liters, 2)} Liter',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${formatDecimal(entry.totalPrice, 2)} €',
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

class _LatestExpenseCard extends StatelessWidget {
  const _LatestExpenseCard({
    required this.expense,
    required this.formattedDate,
    required this.formattedAmount,
    required this.onTap,
  });

  final Expense expense;
  final String formattedDate;
  final String formattedAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
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
                radius: 27,
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$formattedDate · ${expense.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '$formattedAmount €',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

class _NoLatestFuelCard extends StatelessWidget {
  const _NoLatestFuelCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.local_gas_station_outlined),
            SizedBox(width: 12),
            Expanded(child: Text('Noch kein Tankvorgang gespeichert.')),
          ],
        ),
      ),
    );
  }
}

class _NoLatestExpenseCard extends StatelessWidget {
  const _NoLatestExpenseCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.receipt_long_outlined),
            SizedBox(width: 12),
            Expanded(child: Text('Noch keine Ausgabe gespeichert.')),
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
              size: 76,
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
