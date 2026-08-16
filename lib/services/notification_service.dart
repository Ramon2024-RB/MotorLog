import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/maintenance_entry.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    final initialized = await _notifications.initialize(
      settings: initializationSettings,
    );

    debugPrint('MotorLog Notifications initialisiert: $initialized');

    await _initializeTimeZone();

    _initialized = true;
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();

    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));

      debugPrint('MotorLog Zeitzone: ${localTimeZone.identifier}');
    } catch (error) {
      debugPrint('MotorLog Zeitzone konnte nicht ermittelt werden: $error');
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('MotorLog iOS Notification-Berechtigung: $granted');

      return granted ?? false;
    }

    final macOSPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    if (macOSPlugin != null) {
      final granted = await macOSPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('MotorLog macOS Notification-Berechtigung: $granted');

      return granted ?? false;
    }

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();

      debugPrint('MotorLog Android Notification-Berechtigung: $granted');

      return granted ?? false;
    }

    return true;
  }

  int _legacyNotificationId(String maintenanceId) {
    var hash = 0;

    for (final codeUnit in maintenanceId.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);

      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));

      hash ^= hash >> 6;
    }

    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));

    hash ^= hash >> 11;

    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    return hash & 0x7fffffff;
  }

  int _baseNotificationId(String maintenanceId) {
    final legacyId = _legacyNotificationId(maintenanceId);

    return (legacyId & 0x3fffffff) * 2;
  }

  int _advanceNotificationId(String maintenanceId) {
    return _baseNotificationId(maintenanceId);
  }

  int _dueNotificationId(String maintenanceId) {
    return _baseNotificationId(maintenanceId) + 1;
  }

  int _mileageAdvanceNotificationId(String maintenanceId) {
    return (_legacyNotificationId('mileage_advance_$maintenanceId') &
        0x7fffffff);
  }

  int _mileageDueNotificationId(String maintenanceId) {
    return (_legacyNotificationId('mileage_due_$maintenanceId') & 0x7fffffff);
  }

  NotificationDetails _maintenanceNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'motorlog_maintenance',
        'Wartungserinnerungen',
        channelDescription: 'Erinnerungen an anstehende Fahrzeugwartungen',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleMaintenanceNotification(MaintenanceEntry entry) async {
    await initialize();

    await cancelMaintenanceNotification(entry.id);

    final nextDate = entry.nextDate;

    if (nextDate == null) {
      debugPrint('MotorLog: ${entry.title} besitzt kein Fälligkeitsdatum.');

      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    final dueDate = tz.TZDateTime(
      tz.local,
      nextDate.year,
      nextDate.month,
      nextDate.day,
      9,
    );

    final advanceDate = dueDate.subtract(const Duration(days: 7));

    final notificationDetails = _maintenanceNotificationDetails();

    var scheduledNotifications = 0;

    if (advanceDate.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: _advanceNotificationId(entry.id),
        title: 'Wartung steht bald an',
        body: '${entry.title} ist in 7 Tagen fällig.',
        scheduledDate: advanceDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'maintenance_advance:${entry.id}',
      );

      scheduledNotifications++;

      debugPrint('MotorLog: Vorab-Erinnerung geplant');
      debugPrint('Wartung: ${entry.title}');
      debugPrint('Zeitpunkt: $advanceDate');
    } else {
      debugPrint(
        'MotorLog: Keine 7-Tage-Erinnerung für '
        '${entry.title}, da der Zeitpunkt bereits '
        'erreicht oder vergangen ist.',
      );
    }

    if (dueDate.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: _dueNotificationId(entry.id),
        title: 'Wartung heute fällig',
        body: '${entry.title} ist heute fällig.',
        scheduledDate: dueDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'maintenance_due:${entry.id}',
      );

      scheduledNotifications++;

      debugPrint('MotorLog: Fälligkeits-Erinnerung geplant');
      debugPrint('Wartung: ${entry.title}');
      debugPrint('Zeitpunkt: $dueDate');
    } else {
      debugPrint(
        'MotorLog: Keine Fälligkeits-Erinnerung für '
        '${entry.title}, da der Termin bereits '
        'erreicht oder vergangen ist.',
      );
    }

    debugPrint('========================================');
    debugPrint('MOTORLOG WARTUNGSERINNERUNG');
    debugPrint('Wartung: ${entry.title}');
    debugPrint('Fällig: $dueDate');
    debugPrint('Geplante Erinnerungen: $scheduledNotifications');
    debugPrint('========================================');

    await printPendingNotifications();
  }

  Future<void> showMileageAdvanceNotification({
    required MaintenanceEntry entry,
    required int currentMileage,
  }) async {
    await initialize();

    final nextMileage = entry.nextMileage;

    if (nextMileage == null) {
      return;
    }

    final remainingKilometers = nextMileage - currentMileage;

    final body = remainingKilometers > 0
        ? '${entry.title} steht bald an. Noch $remainingKilometers km bis zur Fälligkeit.'
        : '${entry.title} steht bald an.';

    await _notifications.show(
      id: _mileageAdvanceNotificationId(entry.id),
      title: 'Wartung steht bald an',
      body: body,
      notificationDetails: _maintenanceNotificationDetails(),
      payload: 'maintenance_mileage_advance:${entry.id}',
    );

    debugPrint('========================================');
    debugPrint('MOTORLOG KILOMETER-VORWARNUNG');
    debugPrint('Wartung: ${entry.title}');
    debugPrint('Aktueller Kilometerstand: $currentMileage');
    debugPrint('Fällig bei: $nextMileage');
    debugPrint('Rest: $remainingKilometers km');
    debugPrint('========================================');
  }

  Future<void> showMileageDueNotification({
    required MaintenanceEntry entry,
    required int currentMileage,
  }) async {
    await initialize();

    final nextMileage = entry.nextMileage;

    if (nextMileage == null) {
      return;
    }

    final exceededKilometers = currentMileage - nextMileage;

    final body = exceededKilometers > 0
        ? '${entry.title} ist fällig. Der Wartungsstand wurde um $exceededKilometers km überschritten.'
        : '${entry.title} ist jetzt fällig.';

    await _notifications.show(
      id: _mileageDueNotificationId(entry.id),
      title: 'Wartung fällig',
      body: body,
      notificationDetails: _maintenanceNotificationDetails(),
      payload: 'maintenance_mileage_due:${entry.id}',
    );

    debugPrint('========================================');
    debugPrint('MOTORLOG KILOMETER-FÄLLIGKEIT');
    debugPrint('Wartung: ${entry.title}');
    debugPrint('Aktueller Kilometerstand: $currentMileage');
    debugPrint('Fällig bei: $nextMileage');
    debugPrint('Überschritten: $exceededKilometers km');
    debugPrint('========================================');
  }

  Future<void> cancelMaintenanceNotification(String maintenanceId) async {
    await initialize();

    await _notifications.cancel(id: _legacyNotificationId(maintenanceId));

    await _notifications.cancel(id: _advanceNotificationId(maintenanceId));

    await _notifications.cancel(id: _dueNotificationId(maintenanceId));

    debugPrint('MotorLog Wartungsbenachrichtigungen gelöscht: $maintenanceId');
  }

  Future<void> printPendingNotifications() async {
    await initialize();

    final pending = await _notifications.pendingNotificationRequests();

    debugPrint('========================================');
    debugPrint('MOTORLOG GEPLANTE BENACHRICHTIGUNGEN');
    debugPrint('Anzahl: ${pending.length}');

    if (pending.isEmpty) {
      debugPrint('Keine Benachrichtigungen geplant.');
    } else {
      for (final notification in pending) {
        debugPrint('----------------------------------------');
        debugPrint('ID: ${notification.id}');
        debugPrint('Titel: ${notification.title}');
        debugPrint('Text: ${notification.body}');
        debugPrint('Payload: ${notification.payload}');
      }
    }

    debugPrint('========================================');
  }

  Future<void> showTestNotification() async {
    await initialize();

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'motorlog_test',
        'MotorLog Test',
        channelDescription: 'Testbenachrichtigungen von MotorLog',
        importance: Importance.max,
        priority: Priority.max,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      id: 999,
      title: 'MotorLog Test',
      body:
          'Wenn du diese Nachricht siehst, funktionieren die Benachrichtigungen. 🚗',
      notificationDetails: notificationDetails,
    );
  }
}
