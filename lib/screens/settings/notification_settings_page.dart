import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../models/maintenance_entry.dart';
import '../../services/notification_service.dart';
import '../../services/notification_settings_provider.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _isChangingSetting = false;
  bool _isSendingTest = false;

  // ---------------------------------------------------------------------------
  // VORHANDENE WARTUNGEN LADEN
  // ---------------------------------------------------------------------------

  Future<List<MaintenanceEntry>> _getMaintenanceEntries() {
    return AppDatabase.instance.getMaintenanceEntries();
  }

  // ---------------------------------------------------------------------------
  // TERMIN-ERINNERUNGEN FÜR ALLE WARTUNGEN NEU PLANEN
  // ---------------------------------------------------------------------------

  Future<void> _scheduleExistingDateNotifications() async {
    final entries = await _getMaintenanceEntries();

    for (final entry in entries) {
      try {
        await NotificationService.instance.scheduleMaintenanceNotification(
          entry,
        );
      } catch (error) {
        debugPrint(
          'MotorLog: Erinnerung für "${entry.title}" '
          'konnte nicht geplant werden: $error',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TERMIN-ERINNERUNGEN FÜR ALLE WARTUNGEN LÖSCHEN
  // ---------------------------------------------------------------------------

  Future<void> _cancelExistingDateNotifications() async {
    final entries = await _getMaintenanceEntries();

    for (final entry in entries) {
      try {
        await NotificationService.instance.cancelMaintenanceNotification(
          entry.id,
        );
      } catch (error) {
        debugPrint(
          'MotorLog: Erinnerung für "${entry.title}" '
          'konnte nicht entfernt werden: $error',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // KILOMETER-ERINNERUNGEN FÜR ALLE WARTUNGEN LÖSCHEN
  // ---------------------------------------------------------------------------

  Future<void> _cancelExistingMileageNotifications() async {
    final entries = await _getMaintenanceEntries();

    for (final entry in entries) {
      try {
        await NotificationService.instance.cancelMileageNotifications(entry.id);
      } catch (error) {
        debugPrint(
          'MotorLog: Kilometer-Erinnerungen für "${entry.title}" '
          'konnten nicht entfernt werden: $error',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // HAUPTSCHALTER
  // ---------------------------------------------------------------------------

  Future<void> _setMaintenanceNotifications(bool enabled) async {
    if (_isChangingSetting) {
      return;
    }

    setState(() {
      _isChangingSetting = true;
    });

    try {
      if (enabled) {
        final granted = await NotificationService.instance.requestPermissions();

        if (!granted) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Benachrichtigungen wurden vom Gerät nicht erlaubt.',
              ),
            ),
          );

          return;
        }
      }

      await ref
          .read(notificationSettingsProvider.notifier)
          .setMaintenanceNotificationsEnabled(enabled);

      if (enabled) {
        final settings = await ref.read(notificationSettingsProvider.future);

        if (settings.dateNotificationsEnabled) {
          await _scheduleExistingDateNotifications();
        }
      } else {
        await NotificationService.instance.cancelAllNotifications();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Wartungserinnerungen sind aktiviert.'
                : 'Wartungserinnerungen sind deaktiviert.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Einstellung konnte nicht geändert werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSetting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TERMIN-ERINNERUNGEN
  // ---------------------------------------------------------------------------

  Future<void> _setDateNotifications(bool enabled) async {
    if (_isChangingSetting) {
      return;
    }

    setState(() {
      _isChangingSetting = true;
    });

    try {
      await ref
          .read(notificationSettingsProvider.notifier)
          .setDateNotificationsEnabled(enabled);

      if (enabled) {
        await _scheduleExistingDateNotifications();
      } else {
        await _cancelExistingDateNotifications();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Termin-Erinnerungen sind aktiviert.'
                : 'Termin-Erinnerungen sind deaktiviert.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Einstellung konnte nicht geändert werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSetting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // KILOMETER-ERINNERUNGEN
  // ---------------------------------------------------------------------------

  Future<void> _setMileageNotifications(bool enabled) async {
    if (_isChangingSetting) {
      return;
    }

    setState(() {
      _isChangingSetting = true;
    });

    try {
      await ref
          .read(notificationSettingsProvider.notifier)
          .setMileageNotificationsEnabled(enabled);

      if (!enabled) {
        await _cancelExistingMileageNotifications();
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Kilometer-Erinnerungen sind aktiviert.'
                : 'Kilometer-Erinnerungen sind deaktiviert.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Einstellung konnte nicht geändert werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChangingSetting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // TESTBENACHRICHTIGUNG
  // ---------------------------------------------------------------------------

  Future<void> _sendTestNotification() async {
    if (_isSendingTest) {
      return;
    }

    setState(() {
      _isSendingTest = true;
    });

    try {
      await NotificationService.instance.showTestNotification();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Testbenachrichtigung wurde gesendet.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Testbenachrichtigung fehlgeschlagen: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingTest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Zurück',
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: const Text(
          'Benachrichtigungen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: settingsAsync.when(
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
                  Icon(Icons.error_outline, size: 42, color: colors.error),
                  const SizedBox(height: 14),
                  const Text(
                    'Die Benachrichtigungseinstellungen '
                    'konnten nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(notificationSettingsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (settings) {
          final maintenanceEnabled = settings.maintenanceNotificationsEnabled;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: colors.primary,
                      child: Icon(
                        Icons.notifications_active_outlined,
                        size: 34,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nichts Wichtiges verpassen',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MotorLog kann dich an anstehende '
                      'Fahrzeugwartungen und erreichte '
                      'Kilometerstände erinnern.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Wartung',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.build_outlined,
                          color: colors.primary,
                        ),
                      ),
                      title: const Text(
                        'Wartungserinnerungen',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Alle Wartungsbenachrichtigungen '
                        'ein- oder ausschalten',
                      ),
                      value: maintenanceEnabled,
                      onChanged: _isChangingSetting
                          ? null
                          : _setMaintenanceNotifications,
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.calendar_month_outlined,
                          color: maintenanceEnabled
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      title: const Text(
                        'Termin-Erinnerungen',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        '7 Tage vorher und am Fälligkeitstag',
                      ),
                      value: settings.dateNotificationsEnabled,
                      onChanged: !maintenanceEnabled || _isChangingSetting
                          ? null
                          : _setDateNotifications,
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.speed_outlined,
                          color: maintenanceEnabled
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      title: const Text(
                        'Kilometer-Erinnerungen',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Hinweise bei anstehenden und '
                        'fälligen Kilometerständen',
                      ),
                      value: settings.mileageNotificationsEnabled,
                      onChanged: !maintenanceEnabled || _isChangingSetting
                          ? null
                          : _setMileageNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Test',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.notifications_none,
                      color: colors.primary,
                    ),
                  ),
                  title: const Text(
                    'Testbenachrichtigung',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Prüfen, ob Benachrichtigungen '
                    'auf diesem Gerät funktionieren',
                  ),
                  trailing: _isSendingTest
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _isSendingTest ? null : _sendTestNotification,
                ),
              ),

              const SizedBox(height: 22),

              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: colors.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Damit MotorLog Hinweise anzeigen '
                          'kann, müssen Benachrichtigungen '
                          'zusätzlich in den Systemeinstellungen '
                          'deines Geräts erlaubt sein.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
