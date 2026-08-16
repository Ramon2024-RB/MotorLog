import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/expense.dart';
import '../../models/fuel_consumption_interval.dart';
import '../../models/fuel_entry.dart';
import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';
import '../../services/expense_provider.dart';
import '../../services/fuel_entry_provider.dart';
import '../../services/maintenance_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../utils/vehicle_statistics_calculator.dart';
import '../../widgets/motorlog/motorlog_card.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key, this.vehicleId});

  final String? vehicleId;

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _selectedVehicleId = widget.vehicleId;
  }

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

  Vehicle _selectedVehicle(List<Vehicle> vehicles) {
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

  String _formatCurrency(double value) {
    return '${_formatDecimal(value, 2)} €';
  }

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
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
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelAsync = ref.watch(fuelEntryProvider);
    final expensesAsync = ref.watch(expenseProvider);
    final maintenanceAsync = ref.watch(maintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistiken',
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
                    'Die Statistiken konnten nicht geladen werden.',
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
            return const _EmptyStatisticsView();
          }

          final sortedVehicles = _sortVehicles(vehicles);
          final selectedVehicle = _selectedVehicle(vehicles);

          final allFuelEntries = fuelAsync.asData?.value ?? <FuelEntry>[];

          final fuelEntries = allFuelEntries
              .where((entry) => entry.vehicleId == selectedVehicle.id)
              .toList();

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final expenses = allExpenses
              .where((entry) => entry.vehicleId == selectedVehicle.id)
              .toList();

          final allMaintenance =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final maintenanceEntries = allMaintenance
              .where((entry) => entry.vehicleId == selectedVehicle.id)
              .toList();

          final statistics = calculateVehicleStatistics(
            fuelEntries: fuelEntries,
            expenses: expenses,
            maintenanceEntries: maintenanceEntries,
          );

          final consumptionIntervals = calculateFuelConsumptionIntervals(
            fuelEntries,
          );

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
                _VehicleSelectionCard(
                  vehicles: sortedVehicles,
                  selectedVehicle: selectedVehicle,
                  vehicleIcon: _vehicleIcon(selectedVehicle.vehicleType),
                  formattedMileage: _formatMileage(selectedVehicle.mileage),
                  onChanged: (vehicleId) {
                    if (vehicleId == null) {
                      return;
                    }

                    setState(() {
                      _selectedVehicleId = vehicleId;
                    });
                  },
                ),

                const SizedBox(height: 26),

                const _SectionTitle(title: 'Gesamtübersicht'),

                const SizedBox(height: 12),

                _HighlightCard(
                  icon: Icons.euro,
                  title: 'Gesamtkosten',
                  value: _formatCurrency(statistics.totalVehicleCost),
                  subtitle: 'Tanken, Ausgaben und Wartungen zusammen',
                ),

                const SizedBox(height: 12),

                _StatGrid(
                  children: [
                    _StatCard(
                      icon: Icons.speed,
                      title: 'Ø Verbrauch',
                      value: statistics.averageConsumption <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.averageConsumption, 1)} l/100 km',
                    ),
                    _StatCard(
                      icon: Icons.route_outlined,
                      title: 'Ausgewertet',
                      value: '${_formatMileage(statistics.totalDistance)} km',
                    ),
                    _StatCard(
                      icon: Icons.euro_outlined,
                      title: 'Kosten / 100 km',
                      value: statistics.totalDistance <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.costPer100Km, 2)} €',
                    ),
                    _StatCard(
                      icon: Icons.timeline,
                      title: 'Kosten / km',
                      value: statistics.totalDistance <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.costPerKm, 2)} €',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const _SectionTitle(title: 'Verbrauchsentwicklung'),

                const SizedBox(height: 12),

                _ConsumptionChartCard(
                  intervals: consumptionIntervals,
                  averageConsumption: statistics.averageConsumption,
                  formatDecimal: _formatDecimal,
                  formatMileage: _formatMileage,
                ),

                const SizedBox(height: 28),

                const _SectionTitle(title: 'Kraftstoff'),

                const SizedBox(height: 12),

                _StatGrid(
                  children: [
                    _StatCard(
                      icon: Icons.local_gas_station_outlined,
                      title: 'Tankvorgänge',
                      value: statistics.refuels.toString(),
                    ),
                    _StatCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Getankt',
                      value: '${_formatDecimal(statistics.totalFuel, 2)} l',
                    ),
                    _StatCard(
                      icon: Icons.sell_outlined,
                      title: 'Ø Literpreis',
                      value: statistics.averageFuelPrice <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.averageFuelPrice, 3)} €/l',
                    ),
                    _StatCard(
                      icon: Icons.payments_outlined,
                      title: 'Tankkosten',
                      value: _formatCurrency(statistics.totalFuelCost),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const _SectionTitle(title: 'Kostenaufteilung'),

                const SizedBox(height: 12),

                _CostBreakdownCard(
                  fuelCost: statistics.totalFuelCost,
                  expenseCost: statistics.totalExpenseCost,
                  maintenanceCost: statistics.totalMaintenanceCost,
                  totalCost: statistics.totalVehicleCost,
                  formatCurrency: _formatCurrency,
                ),

                const SizedBox(height: 28),

                const _SectionTitle(title: 'Einträge'),

                const SizedBox(height: 12),

                _StatGrid(
                  children: [
                    _StatCard(
                      icon: Icons.local_gas_station_outlined,
                      title: 'Tankvorgänge',
                      value: statistics.refuels.toString(),
                    ),
                    _StatCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Ausgaben',
                      value: statistics.expenses.toString(),
                    ),
                    _StatCard(
                      icon: Icons.build_outlined,
                      title: 'Wartungen',
                      value: statistics.maintenanceEntries.toString(),
                    ),
                    _StatCard(
                      icon: Icons.speed_outlined,
                      title: 'Kilometerstand',
                      value: '${_formatMileage(selectedVehicle.mileage)} km',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConsumptionChartCard extends StatelessWidget {
  const _ConsumptionChartCard({
    required this.intervals,
    required this.averageConsumption,
    required this.formatDecimal,
    required this.formatMileage,
  });

  final List<FuelConsumptionInterval> intervals;
  final double averageConsumption;
  final String Function(double, int) formatDecimal;
  final String Function(int) formatMileage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (intervals.isEmpty) {
      return MotorLogCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colors.primaryContainer,
                child: Icon(Icons.show_chart, color: colors.primary, size: 27),
              ),
              const SizedBox(height: 13),
              const Text(
                'Noch keine Verbrauchswerte',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Für das Diagramm werden mindestens zwei '
                'passende Volltankungen benötigt.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final consumptions = intervals
        .map((interval) => interval.consumption)
        .toList();

    final lowestConsumption = consumptions.reduce(math.min);
    final highestConsumption = consumptions.reduce(math.max);

    var minY = math.max(0.0, lowestConsumption - 2);
    var maxY = highestConsumption + 2;

    if (averageConsumption > 0) {
      minY = math.min(minY, math.max(0.0, averageConsumption - 2));

      maxY = math.max(maxY, averageConsumption + 2);
    }

    if ((maxY - minY) < 4) {
      maxY = minY + 4;
    }

    final spots = <FlSpot>[];

    for (var index = 0; index < intervals.length; index++) {
      spots.add(FlSpot(index.toDouble(), intervals[index].consumption));
    }

    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: colors.primary),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Verbrauch pro Tankperiode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (averageConsumption > 0)
                Text(
                  'Ø ${formatDecimal(averageConsumption, 1)} l',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Berechnet zwischen Volltankungen',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, intervals.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatDecimal(value, 1),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= intervals.length) {
                          return const SizedBox.shrink();
                        }

                        if (intervals.length > 4 &&
                            index != 0 &&
                            index != intervals.length - 1 &&
                            index % 2 != 0) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatMileage(intervals[index].endMileage),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: averageConsumption > 0
                      ? [
                          HorizontalLine(
                            y: averageConsumption,
                            strokeWidth: 1.5,
                            dashArray: [6, 5],
                            color: colors.secondary,
                          ),
                        ]
                      : [],
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.round();

                        if (index < 0 || index >= intervals.length) {
                          return null;
                        }

                        final interval = intervals[index];

                        return LineTooltipItem(
                          '${formatDecimal(interval.consumption, 1)} l/100 km\n'
                          '${formatMileage(interval.endMileage)} km',
                          TextStyle(
                            color: colors.onInverseSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: intervals.length > 2,
                    barWidth: 3,
                    color: colors.primary,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: colors.primary,
                          strokeWidth: 2,
                          strokeColor: colors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 7),
              const Text('Verbrauch', style: TextStyle(fontSize: 12)),
              if (averageConsumption > 0) ...[
                const SizedBox(width: 18),
                Container(
                  width: 18,
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 7),
                const Text('Durchschnitt', style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleSelectionCard extends StatelessWidget {
  const _VehicleSelectionCard({
    required this.vehicles,
    required this.selectedVehicle,
    required this.vehicleIcon,
    required this.formattedMileage,
    required this.onChanged,
  });

  final List<Vehicle> vehicles;
  final Vehicle selectedVehicle;
  final IconData vehicleIcon;
  final String formattedMileage;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: colors.primary,
                  child: Icon(vehicleIcon, color: colors.onPrimary, size: 27),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedVehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedVehicle.brand} '
                        '${selectedVehicle.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.speed, size: 18),
                const SizedBox(width: 7),
                Text(
                  '$formattedMileage km',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            if (vehicles.length > 1) ...[
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: selectedVehicle.id,
                decoration: const InputDecoration(
                  labelText: 'Fahrzeug',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(),
                ),
                items: vehicles.map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle.id,
                    child: Text(vehicle.name),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: colors.primary,
              child: Icon(icon, color: colors.onPrimary, size: 27),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: children,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 23),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 3),
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

class _CostBreakdownCard extends StatelessWidget {
  const _CostBreakdownCard({
    required this.fuelCost,
    required this.expenseCost,
    required this.maintenanceCost,
    required this.totalCost,
    required this.formatCurrency,
  });

  final double fuelCost;
  final double expenseCost;
  final double maintenanceCost;
  final double totalCost;
  final String Function(double) formatCurrency;

  double _percentage(double value) {
    if (totalCost <= 0) {
      return 0;
    }

    return (value / totalCost).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _CostRow(
            icon: Icons.local_gas_station_outlined,
            title: 'Tanken',
            value: formatCurrency(fuelCost),
            progress: _percentage(fuelCost),
          ),

          const SizedBox(height: 20),

          _CostRow(
            icon: Icons.receipt_long_outlined,
            title: 'Sonstige Ausgaben',
            value: formatCurrency(expenseCost),
            progress: _percentage(expenseCost),
          ),

          const SizedBox(height: 20),

          _CostRow(
            icon: Icons.build_outlined,
            title: 'Wartungen',
            value: formatCurrency(maintenanceCost),
            progress: _percentage(maintenanceCost),
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Gesamt',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              Text(
                formatCurrency(totalCost),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String title;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: colors.primary, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),

        const SizedBox(height: 9),

        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(20),
        ),
      ],
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

class _EmptyStatisticsView extends StatelessWidget {
  const _EmptyStatisticsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.query_stats,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 20),

            Text(
              'Noch keine Statistiken',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Lege zuerst ein Fahrzeug an. Danach können '
              'deine Tank-, Kosten- und Wartungsdaten hier '
              'ausgewertet werden.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
