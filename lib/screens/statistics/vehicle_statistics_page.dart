import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

enum _StatisticsPeriod { threeMonths, sixMonths, oneYear, all }

extension _StatisticsPeriodExtension on _StatisticsPeriod {
  String get label {
    switch (this) {
      case _StatisticsPeriod.threeMonths:
        return '3 Monate';
      case _StatisticsPeriod.sixMonths:
        return '6 Monate';
      case _StatisticsPeriod.oneYear:
        return '1 Jahr';
      case _StatisticsPeriod.all:
        return 'Gesamt';
    }
  }

  int? get months {
    switch (this) {
      case _StatisticsPeriod.threeMonths:
        return 3;
      case _StatisticsPeriod.sixMonths:
        return 6;
      case _StatisticsPeriod.oneYear:
        return 12;
      case _StatisticsPeriod.all:
        return null;
    }
  }
}

class VehicleStatisticsPage extends ConsumerStatefulWidget {
  const VehicleStatisticsPage({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleStatisticsPage> createState() {
    return _VehicleStatisticsPageState();
  }
}

class _VehicleStatisticsPageState extends ConsumerState<VehicleStatisticsPage> {
  _StatisticsPeriod _selectedPeriod = _StatisticsPeriod.all;

  Vehicle? _findVehicle(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.id == widget.vehicleId) {
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

  DateTime? _periodStartDate() {
    final months = _selectedPeriod.months;

    if (months == null) {
      return null;
    }

    final now = DateTime.now();

    return DateTime(now.year, now.month - months + 1, 1);
  }

  bool _isInsideSelectedPeriod(DateTime date) {
    final startDate = _periodStartDate();

    if (startDate == null) {
      return true;
    }

    return !date.isBefore(startDate);
  }

  List<FuelEntry> _filterFuelEntries(List<FuelEntry> entries) {
    return entries
        .where((entry) => _isInsideSelectedPeriod(entry.date))
        .toList();
  }

  List<Expense> _filterExpenses(List<Expense> expenses) {
    return expenses
        .where((expense) => _isInsideSelectedPeriod(expense.date))
        .toList();
  }

  List<MaintenanceEntry> _filterMaintenanceEntries(
    List<MaintenanceEntry> entries,
  ) {
    return entries
        .where((entry) => _isInsideSelectedPeriod(entry.date))
        .toList();
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
                  const SizedBox(height: 12),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 18),
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
          final vehicle = _findVehicle(vehicles);

          if (vehicle == null) {
            return const Center(
              child: Text('Das Fahrzeug wurde nicht gefunden.'),
            );
          }

          // -------------------------------------------------------------------
          // Alle Daten des Fahrzeugs
          // -------------------------------------------------------------------

          final allFuelEntries = fuelAsync.asData?.value ?? <FuelEntry>[];

          final vehicleFuelEntries = allFuelEntries
              .where((entry) => entry.vehicleId == vehicle.id)
              .toList();

          final allExpenses = expensesAsync.asData?.value ?? <Expense>[];

          final vehicleExpenses = allExpenses
              .where((entry) => entry.vehicleId == vehicle.id)
              .toList();

          final allMaintenance =
              maintenanceAsync.asData?.value ?? <MaintenanceEntry>[];

          final vehicleMaintenanceEntries = allMaintenance
              .where((entry) => entry.vehicleId == vehicle.id)
              .toList();

          // -------------------------------------------------------------------
          // Zeitraum anwenden
          // -------------------------------------------------------------------

          final fuelEntries = _filterFuelEntries(vehicleFuelEntries);
          final expenses = _filterExpenses(vehicleExpenses);
          final maintenanceEntries = _filterMaintenanceEntries(
            vehicleMaintenanceEntries,
          );

          // -------------------------------------------------------------------
          // Statistiken
          // -------------------------------------------------------------------

          final statistics = calculateVehicleStatistics(
            fuelEntries: fuelEntries,
            expenses: expenses,
            maintenanceEntries: maintenanceEntries,
          );

          final consumptionPoints = _calculateConsumptionPoints(fuelEntries);

          final monthlyCosts = _calculateMonthlyCosts(
            fuelEntries: fuelEntries,
            expenses: expenses,
            maintenanceEntries: maintenanceEntries,
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
                _StatisticsHeader(
                  vehicle: vehicle,
                  totalCost:
                      '${_formatDecimal(statistics.totalVehicleCost, 2)} €',
                  periodLabel: _selectedPeriod.label,
                ),

                const SizedBox(height: 18),

                _PeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onChanged: (period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                ),

                const SizedBox(height: 26),

                _SectionTitle(
                  title: 'Verbrauch',
                  subtitle: _selectedPeriod.label,
                ),

                const SizedBox(height: 12),

                _StatisticsGrid(
                  children: [
                    _StatisticCard(
                      icon: Icons.speed,
                      title: 'Ø Verbrauch',
                      value: statistics.averageConsumption <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.averageConsumption, 1)} l/100 km',
                    ),
                    _StatisticCard(
                      icon: Icons.local_gas_station_outlined,
                      title: 'Ø Kraftstoffpreis',
                      value: statistics.averageFuelPrice <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.averageFuelPrice, 3)} €/l',
                    ),
                    _StatisticCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Kraftstoff',
                      value: '${_formatDecimal(statistics.totalFuel, 2)} l',
                    ),
                    _StatisticCard(
                      icon: Icons.route_outlined,
                      title: 'Ausgewertet',
                      value: '${_formatMileage(statistics.totalDistance)} km',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _SectionTitle(title: 'Kosten', subtitle: _selectedPeriod.label),

                const SizedBox(height: 12),

                _CostOverviewCard(
                  fuelCost: '${_formatDecimal(statistics.totalFuelCost, 2)} €',
                  expenseCost:
                      '${_formatDecimal(statistics.totalExpenseCost, 2)} €',
                  maintenanceCost:
                      '${_formatDecimal(statistics.totalMaintenanceCost, 2)} €',
                  totalCost:
                      '${_formatDecimal(statistics.totalVehicleCost, 2)} €',
                ),

                const SizedBox(height: 12),

                _StatisticsGrid(
                  children: [
                    _StatisticCard(
                      icon: Icons.euro_outlined,
                      title: 'Kosten / km',
                      value: statistics.costPerKm <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.costPerKm, 2)} €',
                    ),
                    _StatisticCard(
                      icon: Icons.route,
                      title: 'Kosten / 100 km',
                      value: statistics.costPer100Km <= 0
                          ? '–'
                          : '${_formatDecimal(statistics.costPer100Km, 2)} €',
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                _SectionTitle(
                  title: 'Einträge',
                  subtitle: _selectedPeriod.label,
                ),

                const SizedBox(height: 12),

                _EntryOverviewCard(
                  refuels: statistics.refuels,
                  expenses: statistics.expenses,
                  maintenanceEntries: statistics.maintenanceEntries,
                ),

                const SizedBox(height: 28),

                _SectionTitle(
                  title: 'Diagramme',
                  subtitle: _selectedPeriod.label,
                ),

                const SizedBox(height: 12),

                _ConsumptionChartCard(
                  points: consumptionPoints,
                  averageConsumption: statistics.averageConsumption,
                  formatDecimal: _formatDecimal,
                  formatMileage: _formatMileage,
                ),

                const SizedBox(height: 12),

                _CostDevelopmentChartCard(
                  months: monthlyCosts,
                  formatDecimal: _formatDecimal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ZEITRAUM
// ============================================================================

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final _StatisticsPeriod selectedPeriod;
  final ValueChanged<_StatisticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: _StatisticsPeriod.values.map((period) {
          final selected = period == selectedPeriod;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  onChanged(period);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    period.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================================
// VERBRAUCH
// ============================================================================

class _ConsumptionPoint {
  const _ConsumptionPoint({required this.mileage, required this.consumption});

  final int mileage;
  final double consumption;
}

List<_ConsumptionPoint> _calculateConsumptionPoints(List<FuelEntry> entries) {
  if (entries.length < 2) {
    return const [];
  }

  final sorted = [...entries]
    ..sort((a, b) {
      final mileageComparison = a.mileage.compareTo(b.mileage);

      if (mileageComparison != 0) {
        return mileageComparison;
      }

      return a.date.compareTo(b.date);
    });

  final points = <_ConsumptionPoint>[];

  FuelEntry? previousFullTank;
  double fuelSincePreviousFullTank = 0;

  for (final entry in sorted) {
    if (previousFullTank == null) {
      if (entry.isFullTank) {
        previousFullTank = entry;
        fuelSincePreviousFullTank = 0;
      }

      continue;
    }

    fuelSincePreviousFullTank += entry.liters;

    if (!entry.isFullTank) {
      continue;
    }

    final distance = entry.mileage - previousFullTank.mileage;

    if (distance > 0 && fuelSincePreviousFullTank > 0) {
      final consumption = fuelSincePreviousFullTank / distance * 100;

      points.add(
        _ConsumptionPoint(mileage: entry.mileage, consumption: consumption),
      );
    }

    previousFullTank = entry;
    fuelSincePreviousFullTank = 0;
  }

  return points;
}

class _ConsumptionChartCard extends StatelessWidget {
  const _ConsumptionChartCard({
    required this.points,
    required this.averageConsumption,
    required this.formatDecimal,
    required this.formatMileage,
  });

  final List<_ConsumptionPoint> points;
  final double averageConsumption;
  final String Function(double, int) formatDecimal;
  final String Function(int) formatMileage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (points.isEmpty) {
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
                'Für diesen Zeitraum werden mindestens zwei '
                'passende Volltankungen benötigt.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final consumptions = points.map((point) => point.consumption).toList();

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

    for (var index = 0; index < points.length; index++) {
      spots.add(FlSpot(index.toDouble(), points[index].consumption));
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
                  'Verbrauchsverlauf',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
            'Verbrauch zwischen den Volltankungen',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: math.max(1, points.length - 1).toDouble(),
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
                      reservedSize: 36,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }

                        if (points.length > 4 &&
                            index != 0 &&
                            index != points.length - 1 &&
                            index % 2 != 0) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            formatMileage(points[index].mileage),
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

                        if (index < 0 || index >= points.length) {
                          return null;
                        }

                        final point = points[index];

                        return LineTooltipItem(
                          '${formatDecimal(point.consumption, 1)} l/100 km\n'
                          '${formatMileage(point.mileage)} km',
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
                    isCurved: points.length > 2,
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
        ],
      ),
    );
  }
}

// ============================================================================
// MONATLICHE KOSTEN
// ============================================================================

class _MonthlyCost {
  const _MonthlyCost({
    required this.year,
    required this.month,
    required this.fuelCost,
    required this.expenseCost,
    required this.maintenanceCost,
  });

  final int year;
  final int month;
  final double fuelCost;
  final double expenseCost;
  final double maintenanceCost;

  double get totalCost {
    return fuelCost + expenseCost + maintenanceCost;
  }

  String get label {
    const monthNames = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];

    return '${monthNames[month - 1]} '
        '${year.toString().substring(2)}';
  }
}

class _MutableMonthlyCost {
  _MutableMonthlyCost({required this.year, required this.month});

  final int year;
  final int month;

  double fuelCost = 0;
  double expenseCost = 0;
  double maintenanceCost = 0;
}

List<_MonthlyCost> _calculateMonthlyCosts({
  required List<FuelEntry> fuelEntries,
  required List<Expense> expenses,
  required List<MaintenanceEntry> maintenanceEntries,
}) {
  final map = <String, _MutableMonthlyCost>{};

  _MutableMonthlyCost getMonth(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

    return map.putIfAbsent(
      key,
      () => _MutableMonthlyCost(year: date.year, month: date.month),
    );
  }

  for (final entry in fuelEntries) {
    getMonth(entry.date).fuelCost += entry.totalPrice;
  }

  for (final expense in expenses) {
    getMonth(expense.date).expenseCost += expense.amount;
  }

  for (final maintenance in maintenanceEntries) {
    getMonth(maintenance.date).maintenanceCost += maintenance.cost;
  }

  final months = map.values.map((month) {
    return _MonthlyCost(
      year: month.year,
      month: month.month,
      fuelCost: month.fuelCost,
      expenseCost: month.expenseCost,
      maintenanceCost: month.maintenanceCost,
    );
  }).toList();

  months.sort((a, b) {
    final yearComparison = a.year.compareTo(b.year);

    if (yearComparison != 0) {
      return yearComparison;
    }

    return a.month.compareTo(b.month);
  });

  return months;
}

class _CostDevelopmentChartCard extends StatelessWidget {
  const _CostDevelopmentChartCard({
    required this.months,
    required this.formatDecimal,
  });

  final List<_MonthlyCost> months;
  final String Function(double, int) formatDecimal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (months.isEmpty) {
      return MotorLogCard(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.bar_chart_outlined,
                  color: colors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                'Noch keine Kostenentwicklung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Für den ausgewählten Zeitraum wurden '
                'noch keine Kosten gespeichert.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final highestTotal = months
        .map((month) => month.totalCost)
        .reduce(math.max);

    var maxY = highestTotal * 1.20;

    if (maxY <= 0) {
      maxY = 100;
    }

    if (maxY < 50) {
      maxY = 50;
    }

    final interval = maxY / 4;

    final groups = <BarChartGroupData>[];

    for (var index = 0; index < months.length; index++) {
      final month = months[index];

      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: month.totalCost,
              width: months.length <= 3 ? 28 : 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              color: colors.primary,
            ),
          ],
        ),
      );
    }

    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_outlined, color: colors.primary),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Kostenentwicklung',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Gesamtkosten pro Monat',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barGroups: groups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
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
                      reservedSize: 48,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${value.round()} €',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();

                        if (index < 0 || index >= months.length) {
                          return const SizedBox.shrink();
                        }

                        if (months.length > 6 &&
                            index != 0 &&
                            index != months.length - 1 &&
                            index % 2 != 0) {
                          return const SizedBox.shrink();
                        }

                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            months[index].label,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= months.length) {
                        return null;
                      }

                      final month = months[groupIndex];

                      return BarTooltipItem(
                        '${month.label}\n'
                        '${formatDecimal(month.totalCost, 2)} €\n'
                        'Tanken: ${formatDecimal(month.fuelCost, 2)} €\n'
                        'Ausgaben: ${formatDecimal(month.expenseCost, 2)} €\n'
                        'Wartung: ${formatDecimal(month.maintenanceCost, 2)} €',
                        TextStyle(
                          color: colors.onInverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _CostLegend(
            fuelCost: months.fold<double>(
              0,
              (sum, month) => sum + month.fuelCost,
            ),
            expenseCost: months.fold<double>(
              0,
              (sum, month) => sum + month.expenseCost,
            ),
            maintenanceCost: months.fold<double>(
              0,
              (sum, month) => sum + month.maintenanceCost,
            ),
            formatDecimal: formatDecimal,
          ),
        ],
      ),
    );
  }
}

class _CostLegend extends StatelessWidget {
  const _CostLegend({
    required this.fuelCost,
    required this.expenseCost,
    required this.maintenanceCost,
    required this.formatDecimal,
  });

  final double fuelCost;
  final double expenseCost;
  final double maintenanceCost;
  final String Function(double, int) formatDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CostLegendRow(
          icon: Icons.local_gas_station_outlined,
          title: 'Tanken',
          value: '${formatDecimal(fuelCost, 2)} €',
        ),
        const SizedBox(height: 8),
        _CostLegendRow(
          icon: Icons.receipt_long_outlined,
          title: 'Sonstige Ausgaben',
          value: '${formatDecimal(expenseCost, 2)} €',
        ),
        const SizedBox(height: 8),
        _CostLegendRow(
          icon: Icons.build_outlined,
          title: 'Wartungen',
          value: '${formatDecimal(maintenanceCost, 2)} €',
        ),
      ],
    );
  }
}

class _CostLegendRow extends StatelessWidget {
  const _CostLegendRow({
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

    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ============================================================================
// ALLGEMEINE UI
// ============================================================================

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader({
    required this.vehicle,
    required this.totalCost,
    required this.periodLabel,
  });

  final Vehicle vehicle;
  final String totalCost;
  final String periodLabel;

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
    final colors = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: colors.primary,
                  child: Icon(
                    _vehicleIcon(),
                    color: colors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gesamtkosten',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              totalCost,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: children,
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
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
            Icon(icon, color: colors.primary, size: 24),
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

class _CostOverviewCard extends StatelessWidget {
  const _CostOverviewCard({
    required this.fuelCost,
    required this.expenseCost,
    required this.maintenanceCost,
    required this.totalCost,
  });

  final String fuelCost;
  final String expenseCost;
  final String maintenanceCost;
  final String totalCost;

  @override
  Widget build(BuildContext context) {
    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _CostRow(
            icon: Icons.local_gas_station_outlined,
            title: 'Tankkosten',
            value: fuelCost,
          ),
          const Divider(height: 24),
          _CostRow(
            icon: Icons.receipt_long_outlined,
            title: 'Sonstige Ausgaben',
            value: expenseCost,
          ),
          const Divider(height: 24),
          _CostRow(
            icon: Icons.build_outlined,
            title: 'Wartungskosten',
            value: maintenanceCost,
          ),
          const Divider(height: 28),
          _CostRow(
            icon: Icons.euro,
            title: 'Gesamtkosten',
            value: totalCost,
            emphasize: true,
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
    this.emphasize = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colors.primaryContainer,
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: emphasize ? 18 : 15,
          ),
        ),
      ],
    );
  }
}

class _EntryOverviewCard extends StatelessWidget {
  const _EntryOverviewCard({
    required this.refuels,
    required this.expenses,
    required this.maintenanceEntries,
  });

  final int refuels;
  final int expenses;
  final int maintenanceEntries;

  @override
  Widget build(BuildContext context) {
    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _EntryRow(
            icon: Icons.local_gas_station_outlined,
            title: 'Tankvorgänge',
            value: refuels.toString(),
          ),
          const Divider(height: 24),
          _EntryRow(
            icon: Icons.receipt_long_outlined,
            title: 'Ausgaben',
            value: expenses.toString(),
          ),
          const Divider(height: 24),
          _EntryRow(
            icon: Icons.build_outlined,
            title: 'Wartungen',
            value: maintenanceEntries.toString(),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}
