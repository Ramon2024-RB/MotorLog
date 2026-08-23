import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    required this.maintenanceNotificationsEnabled,
    required this.dateNotificationsEnabled,
    required this.mileageNotificationsEnabled,
  });

  final bool maintenanceNotificationsEnabled;
  final bool dateNotificationsEnabled;
  final bool mileageNotificationsEnabled;

  NotificationSettings copyWith({
    bool? maintenanceNotificationsEnabled,
    bool? dateNotificationsEnabled,
    bool? mileageNotificationsEnabled,
  }) {
    return NotificationSettings(
      maintenanceNotificationsEnabled:
          maintenanceNotificationsEnabled ??
          this.maintenanceNotificationsEnabled,
      dateNotificationsEnabled:
          dateNotificationsEnabled ?? this.dateNotificationsEnabled,
      mileageNotificationsEnabled:
          mileageNotificationsEnabled ?? this.mileageNotificationsEnabled,
    );
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      NotificationSettingsNotifier.new,
    );

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  static const _maintenanceKey = 'notifications_maintenance_enabled';
  static const _dateKey = 'notifications_date_enabled';
  static const _mileageKey = 'notifications_mileage_enabled';

  @override
  Future<NotificationSettings> build() async {
    final preferences = await SharedPreferences.getInstance();

    return NotificationSettings(
      maintenanceNotificationsEnabled:
          preferences.getBool(_maintenanceKey) ?? true,
      dateNotificationsEnabled: preferences.getBool(_dateKey) ?? true,
      mileageNotificationsEnabled: preferences.getBool(_mileageKey) ?? true,
    );
  }

  Future<void> setMaintenanceNotificationsEnabled(bool enabled) async {
    final current = await future;
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_maintenanceKey, enabled);

    state = AsyncData(
      current.copyWith(maintenanceNotificationsEnabled: enabled),
    );
  }

  Future<void> setDateNotificationsEnabled(bool enabled) async {
    final current = await future;
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_dateKey, enabled);

    state = AsyncData(current.copyWith(dateNotificationsEnabled: enabled));
  }

  Future<void> setMileageNotificationsEnabled(bool enabled) async {
    final current = await future;
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_mileageKey, enabled);

    state = AsyncData(current.copyWith(mileageNotificationsEnabled: enabled));
  }
}
