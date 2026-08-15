import 'package:flutter/material.dart';

import '../models/maintenance_entry.dart';
import '../models/vehicle.dart';

enum MaintenanceStatusType { overdue, dueSoon, okay, noReminder }

class MaintenanceStatus {
  const MaintenanceStatus({
    required this.type,
    required this.label,
    required this.priority,
  });

  final MaintenanceStatusType type;
  final String label;
  final int priority;

  bool get isOverdue => type == MaintenanceStatusType.overdue;

  bool get isDueSoon => type == MaintenanceStatusType.dueSoon;

  bool get hasReminder => type != MaintenanceStatusType.noReminder;
}

MaintenanceStatus calculateMaintenanceStatus({
  required MaintenanceEntry entry,
  required Vehicle? vehicle,
}) {
  final today = DateUtils.dateOnly(DateTime.now());

  final nextDate = entry.nextDate == null
      ? null
      : DateUtils.dateOnly(entry.nextDate!);

  final currentMileage = vehicle?.mileage;
  final nextMileage = entry.nextMileage;

  // ------------------------------------------------------------
  // 1. Überfällig
  // ------------------------------------------------------------

  final dateOverdue = nextDate != null && !nextDate.isAfter(today);

  final mileageOverdue =
      nextMileage != null &&
      currentMileage != null &&
      currentMileage >= nextMileage;

  if (dateOverdue || mileageOverdue) {
    return const MaintenanceStatus(
      type: MaintenanceStatusType.overdue,
      label: 'Überfällig',
      priority: 0,
    );
  }

  // ------------------------------------------------------------
  // 2. Restzeit / Restkilometer berechnen
  // ------------------------------------------------------------

  final daysRemaining = nextDate?.difference(today).inDays;

  final kilometersRemaining = nextMileage == null || currentMileage == null
      ? null
      : nextMileage - currentMileage;

  // ------------------------------------------------------------
  // 3. Bald fällig
  //
  // Datum: innerhalb der nächsten 30 Tage
  // Kilometer: innerhalb der nächsten 1.000 km
  // ------------------------------------------------------------

  final dateDueSoon =
      daysRemaining != null && daysRemaining >= 0 && daysRemaining <= 30;

  final mileageDueSoon =
      kilometersRemaining != null &&
      kilometersRemaining >= 0 &&
      kilometersRemaining <= 1000;

  if (dateDueSoon || mileageDueSoon) {
    return const MaintenanceStatus(
      type: MaintenanceStatusType.dueSoon,
      label: 'Bald fällig',
      priority: 1,
    );
  }

  // ------------------------------------------------------------
  // 4. Erinnerung vorhanden, aber noch nicht bald fällig
  // ------------------------------------------------------------

  if (nextDate != null || nextMileage != null) {
    return const MaintenanceStatus(
      type: MaintenanceStatusType.okay,
      label: 'Geplant',
      priority: 2,
    );
  }

  // ------------------------------------------------------------
  // 5. Keine Erinnerung hinterlegt
  // ------------------------------------------------------------

  return const MaintenanceStatus(
    type: MaintenanceStatusType.noReminder,
    label: 'Keine Erinnerung',
    priority: 3,
  );
}

int? maintenanceDaysRemaining(MaintenanceEntry entry) {
  if (entry.nextDate == null) {
    return null;
  }

  final today = DateUtils.dateOnly(DateTime.now());
  final nextDate = DateUtils.dateOnly(entry.nextDate!);

  return nextDate.difference(today).inDays;
}

int? maintenanceKilometersRemaining({
  required MaintenanceEntry entry,
  required Vehicle? vehicle,
}) {
  if (entry.nextMileage == null || vehicle == null) {
    return null;
  }

  return entry.nextMileage! - vehicle.mileage;
}
