import 'package:flutter/material.dart';

import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';

enum DashboardMaintenanceStatusType { overdue, dueSoon, okay, noReminder }

class DashboardMaintenanceCard extends StatelessWidget {
  const DashboardMaintenanceCard({
    super.key,
    required this.vehicle,
    required this.entries,
    required this.onTap,
  });

  final Vehicle vehicle;
  final List<MaintenanceEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items =
        entries.map((entry) {
          return _DashboardMaintenanceItem(
            entry: entry,
            status: _DashboardMaintenanceStatus.calculate(
              entry: entry,
              vehicle: vehicle,
            ),
          );
        }).toList()..sort((first, second) {
          final priorityComparison = first.status.priority.compareTo(
            second.status.priority,
          );

          if (priorityComparison != 0) {
            return priorityComparison;
          }

          return second.entry.date.compareTo(first.entry.date);
        });

    final overdueItems = items
        .where(
          (item) => item.status.type == DashboardMaintenanceStatusType.overdue,
        )
        .toList();

    final dueSoonItems = items
        .where(
          (item) => item.status.type == DashboardMaintenanceStatusType.dueSoon,
        )
        .toList();

    final importantItems = [...overdueItems, ...dueSoonItems].take(3).toList();

    if (importantItems.isEmpty) {
      return _OkayCard(
        vehicleName: vehicle.name,
        hasMaintenance: entries.isNotEmpty,
        onTap: onTap,
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHeader(
                overdueCount: overdueItems.length,
                dueSoonCount: dueSoonItems.length,
              ),
              const SizedBox(height: 16),
              ...List.generate(importantItems.length, (index) {
                final item = importantItems[index];

                return Column(
                  children: [
                    _ReminderRow(item: item, vehicle: vehicle),
                    if (index < importantItems.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                  ],
                );
              }),
              if (overdueItems.length + dueSoonItems.length > 3) ...[
                const SizedBox(height: 14),
                Text(
                  '${overdueItems.length + dueSoonItems.length - 3} weitere Wartungen anzeigen',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMaintenanceItem {
  const _DashboardMaintenanceItem({required this.entry, required this.status});

  final MaintenanceEntry entry;
  final _DashboardMaintenanceStatus status;
}

class _DashboardMaintenanceStatus {
  const _DashboardMaintenanceStatus({
    required this.type,
    required this.label,
    required this.priority,
  });

  final DashboardMaintenanceStatusType type;
  final String label;
  final int priority;

  static _DashboardMaintenanceStatus calculate({
    required MaintenanceEntry entry,
    required Vehicle vehicle,
  }) {
    final today = DateUtils.dateOnly(DateTime.now());

    final nextDate = switch (entry.nextDate) {
      final date? => DateUtils.dateOnly(date),
      null => null,
    };

    final nextMileage = entry.nextMileage;

    final dateOverdue = nextDate != null && !nextDate.isAfter(today);

    final mileageOverdue =
        nextMileage != null && vehicle.mileage >= nextMileage;

    if (dateOverdue || mileageOverdue) {
      return const _DashboardMaintenanceStatus(
        type: DashboardMaintenanceStatusType.overdue,
        label: 'Überfällig',
        priority: 0,
      );
    }

    final daysRemaining = nextDate?.difference(today).inDays;

    final kilometersRemaining = nextMileage == null
        ? null
        : nextMileage - vehicle.mileage;

    final dateDueSoon = daysRemaining != null && daysRemaining <= 30;

    final mileageDueSoon =
        kilometersRemaining != null && kilometersRemaining <= 1000;

    if (dateDueSoon || mileageDueSoon) {
      return const _DashboardMaintenanceStatus(
        type: DashboardMaintenanceStatusType.dueSoon,
        label: 'Bald fällig',
        priority: 1,
      );
    }

    if (nextDate != null || nextMileage != null) {
      return const _DashboardMaintenanceStatus(
        type: DashboardMaintenanceStatusType.okay,
        label: 'Alles aktuell',
        priority: 2,
      );
    }

    return const _DashboardMaintenanceStatus(
      type: DashboardMaintenanceStatusType.noReminder,
      label: 'Keine Erinnerung',
      priority: 3,
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.overdueCount, required this.dueSoonCount});

  final int overdueCount;
  final int dueSoonCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasOverdue = overdueCount > 0;

    final statusColor = hasOverdue ? colorScheme.error : colorScheme.tertiary;

    final title = hasOverdue
        ? '$overdueCount Wartung${overdueCount == 1 ? '' : 'en'} überfällig'
        : '$dueSoonCount Wartung${dueSoonCount == 1 ? '' : 'en'} bald fällig';

    return Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Icon(
            hasOverdue ? Icons.error_outline : Icons.warning_amber_rounded,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasOverdue
                    ? 'Bitte möglichst bald erledigen.'
                    : 'Diese Arbeiten stehen demnächst an.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.item, required this.vehicle});

  final _DashboardMaintenanceItem item;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isOverdue =
        item.status.type == DashboardMaintenanceStatusType.overdue;

    final statusColor = isOverdue ? colorScheme.error : colorScheme.tertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 72,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.entry.category,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (item.entry.nextMileage != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(Icons.speed, size: 17),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Bei ${_formatMileage(item.entry.nextMileage!)} km'
                        '${_remainingMileageText()}',
                      ),
                    ),
                  ],
                ),
              ],
              if (item.entry.nextDate != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Am ${_formatDate(item.entry.nextDate!)}'
                        '${_remainingDateText()}',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _remainingMileageText() {
    final nextMileage = item.entry.nextMileage;

    if (nextMileage == null) {
      return '';
    }

    final remaining = nextMileage - vehicle.mileage;

    if (remaining < 0) {
      return ' · ${_formatMileage(remaining.abs())} km überfällig';
    }

    if (remaining == 0) {
      return ' · jetzt fällig';
    }

    return ' · noch ${_formatMileage(remaining)} km';
  }

  String _remainingDateText() {
    final nextDate = item.entry.nextDate;

    if (nextDate == null) {
      return '';
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(nextDate);
    final remaining = date.difference(today).inDays;

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

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
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

class _OkayCard extends StatelessWidget {
  const _OkayCard({
    required this.vehicleName,
    required this.hasMaintenance,
    required this.onTap,
  });

  final String vehicleName;
  final bool hasMaintenance;
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
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  hasMaintenance
                      ? Icons.check_circle_outline
                      : Icons.build_outlined,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasMaintenance
                          ? 'Alles aktuell'
                          : 'Noch kein Wartungsplan',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasMaintenance
                          ? 'Für $vehicleName ist derzeit keine Wartung fällig.'
                          : 'Lege für $vehicleName eine Wartung mit Erinnerung an.',
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
