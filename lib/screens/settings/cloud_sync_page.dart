import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/cloud_sync_service.dart';
import '../../services/expense_provider.dart';
import '../../services/fuel_entry_provider.dart';
import '../../services/premium_provider.dart';
import '../../services/vehicle_provider.dart';

class CloudSyncPage extends ConsumerStatefulWidget {
  const CloudSyncPage({super.key});

  @override
  ConsumerState<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends ConsumerState<CloudSyncPage> {
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;

  bool _isLoadingCloudStatus = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  int? _cloudVehicleCount;
  int? _cloudFuelEntryCount;
  int? _cloudExpenseCount;

  String? _cloudStatusError;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadCloudStatus);
  }

  // ---------------------------------------------------------------------------
  // CLOUD-STATUS
  // ---------------------------------------------------------------------------

  Future<void> _loadCloudStatus() async {
    if (!mounted) {
      return;
    }

    try {
      final isPremium = await ref.read(premiumProvider.future);

      if (!mounted) {
        return;
      }

      if (!isPremium) {
        setState(() {
          _cloudVehicleCount = null;
          _cloudFuelEntryCount = null;
          _cloudExpenseCount = null;
          _cloudStatusError = null;
          _isLoadingCloudStatus = false;
        });

        return;
      }

      setState(() {
        _isLoadingCloudStatus = true;
        _cloudStatusError = null;
      });

      final results = await Future.wait<int>([
        _cloudSyncService.getCloudVehicleCount(),
        _cloudSyncService.getCloudFuelEntryCount(),
        _cloudSyncService.getCloudExpenseCount(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _cloudVehicleCount = results[0];
        _cloudFuelEntryCount = results[1];
        _cloudExpenseCount = results[2];
        _isLoadingCloudStatus = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cloudStatusError = error.toString();
        _isLoadingCloudStatus = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LOKALE DATEN IN DIE CLOUD SICHERN
  // ---------------------------------------------------------------------------

  Future<void> _backupLocalData() async {
    if (_isBackingUp || _isRestoring) {
      return;
    }

    final shouldBackup = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.cloud_upload_outlined),
          title: const Text('Lokale Daten sichern?'),
          content: const Text(
            'Deine lokal gespeicherten Fahrzeuge, Tankvorgänge und Kosten '
            'werden in der MotorLog Cloud gesichert.\n\n'
            'Bereits vorhandene Cloud-Einträge mit derselben ID werden '
            'aktualisiert.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Jetzt sichern'),
            ),
          ],
        );
      },
    );

    if (shouldBackup != true || !mounted) {
      return;
    }

    setState(() {
      _isBackingUp = true;
    });

    try {
      final isPremium = await ref.read(premiumProvider.future);

      if (!isPremium) {
        throw StateError(
          'Cloud-Backup ist nur mit MotorLog Premium verfügbar.',
        );
      }

      // Reihenfolge:
      // Erst Fahrzeuge, danach abhängige Tankvorgänge und Kosten.
      await ref.read(vehicleProvider.notifier).uploadAllVehiclesToCloud();

      await ref.read(fuelEntryProvider.notifier).uploadAllFuelEntriesToCloud();

      await ref.read(expenseProvider.notifier).uploadAllExpensesToCloud();

      if (!mounted) {
        return;
      }

      setState(() {
        _isBackingUp = false;
      });

      await _loadCloudStatus();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokale Daten wurden erfolgreich in der Cloud gesichert.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBackingUp = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud-Backup fehlgeschlagen: $error')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CLOUD-DATEN WIEDERHERSTELLEN
  // ---------------------------------------------------------------------------

  Future<void> _restoreCloudData() async {
    if (_isRestoring || _isBackingUp) {
      return;
    }

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.cloud_download_outlined),
          title: const Text('Cloud-Daten wiederherstellen?'),
          content: const Text(
            'Deine in der MotorLog Cloud gespeicherten Fahrzeuge, '
            'Tankvorgänge und Kosten werden auf dieses Gerät übertragen.\n\n'
            'Einträge mit derselben ID werden aktualisiert. Andere lokale '
            'Daten werden dabei nicht gelöscht.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Wiederherstellen'),
            ),
          ],
        );
      },
    );

    if (shouldRestore != true || !mounted) {
      return;
    }

    setState(() {
      _isRestoring = true;
    });

    try {
      // Fahrzeuge zuerst wiederherstellen.
      //
      // Tankvorgänge und Kosten gehören jeweils über vehicleId
      // zu einem Fahrzeug.
      final restoredVehicleCount = await ref
          .read(vehicleProvider.notifier)
          .restoreVehiclesFromCloud();

      final restoredFuelEntryCount = await ref
          .read(fuelEntryProvider.notifier)
          .restoreFuelEntriesFromCloud();

      final restoredExpenseCount = await ref
          .read(expenseProvider.notifier)
          .restoreExpensesFromCloud();

      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wiederhergestellt: '
            '$restoredVehicleCount ${_vehicleLabel(restoredVehicleCount)}, '
            '$restoredFuelEntryCount '
            '${_fuelEntryLabel(restoredFuelEntryCount)} und '
            '$restoredExpenseCount ${_expenseLabel(restoredExpenseCount)}.',
          ),
        ),
      );

      await _loadCloudStatus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wiederherstellung fehlgeschlagen: $error')),
      );
    }
  }

  String _vehicleLabel(int count) {
    return count == 1 ? 'Fahrzeug' : 'Fahrzeuge';
  }

  String _fuelEntryLabel(int count) {
    return count == 1 ? 'Tankvorgang' : 'Tankvorgänge';
  }

  String _expenseLabel(int count) {
    return count == 1 ? 'Kosteneintrag' : 'Kosteneinträge';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final premiumAsync = ref.watch(premiumProvider);

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
          'Cloud & Synchronisierung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(premiumProvider.notifier).reload();
          await _loadCloudStatus();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      Icons.cloud_done_outlined,
                      size: 34,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MotorLog Cloud',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sichere deine Fahrzeugdaten und stelle sie auf '
                    'deinen Geräten wieder her.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Cloud-Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            premiumAsync.when(
              loading: () {
                return const _StatusCard(
                  icon: Icons.hourglass_top,
                  title: 'Tarif wird geprüft',
                  subtitle: 'Einen Moment bitte ...',
                  showProgress: true,
                );
              },
              error: (error, stackTrace) {
                return _StatusCard(
                  icon: Icons.error_outline,
                  title: 'Tarif konnte nicht geladen werden',
                  subtitle:
                      'Ziehe die Seite nach unten, um es erneut '
                      'zu versuchen.',
                  iconColor: colors.error,
                );
              },
              data: (isPremium) {
                if (!isPremium) {
                  return _FreeCard(
                    onPremiumTap: () {
                      context.push('/premium');
                    },
                  );
                }

                return _PremiumStatusCard(
                  isLoading: _isLoadingCloudStatus,
                  cloudVehicleCount: _cloudVehicleCount,
                  cloudFuelEntryCount: _cloudFuelEntryCount,
                  cloudExpenseCount: _cloudExpenseCount,
                  error: _cloudStatusError,
                  onRetry: _loadCloudStatus,
                );
              },
            ),

            const SizedBox(height: 28),

            Text(
              'Backup',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            premiumAsync.when(
              loading: () {
                return const _CloudActionUnavailableCard(
                  text: 'Tarif wird geladen ...',
                );
              },
              error: (error, stackTrace) {
                return const _CloudActionUnavailableCard(
                  text: 'Cloud-Funktion momentan nicht verfügbar.',
                );
              },
              data: (isPremium) {
                if (!isPremium) {
                  return const _CloudActionUnavailableCard(
                    text: 'Cloud-Backups sind mit MotorLog Premium verfügbar.',
                  );
                }

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lokale Daten sichern',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Sichere Fahrzeuge, Tankvorgänge und '
                                    'Kosten dieses Geräts in der Cloud.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isBackingUp || _isRestoring
                                ? null
                                : _backupLocalData,
                            icon: _isBackingUp
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              _isBackingUp
                                  ? 'Backup läuft ...'
                                  : 'Lokale Daten jetzt sichern',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            Text(
              'Wiederherstellung',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            premiumAsync.when(
              loading: () {
                return const _CloudActionUnavailableCard(
                  text: 'Tarif wird geladen ...',
                );
              },
              error: (error, stackTrace) {
                return const _CloudActionUnavailableCard(
                  text: 'Cloud-Funktion momentan nicht verfügbar.',
                );
              },
              data: (isPremium) {
                if (!isPremium) {
                  return const _CloudActionUnavailableCard(
                    text:
                        'Die Cloud-Wiederherstellung ist mit MotorLog Premium '
                        'verfügbar.',
                  );
                }

                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              child: Icon(
                                Icons.cloud_download_outlined,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cloud-Daten wiederherstellen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Lade deine Fahrzeuge, Tankvorgänge und '
                                    'Kosten aus der MotorLog Cloud.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isRestoring || _isBackingUp
                                ? null
                                : _restoreCloudData,
                            icon: _isRestoring
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_download_outlined),
                            label: Text(
                              _isRestoring
                                  ? 'Wiederherstellung läuft ...'
                                  : 'Aus Cloud wiederherstellen',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: colors.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MotorLog speichert deine Daten weiterhin lokal auf '
                        'dem Gerät. Die Cloud ergänzt diese lokale Speicherung '
                        'für Premium-Konten.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({
    required this.isLoading,
    required this.cloudVehicleCount,
    required this.cloudFuelEntryCount,
    required this.cloudExpenseCount,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final int? cloudVehicleCount;
  final int? cloudFuelEntryCount;
  final int? cloudExpenseCount;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.verified_outlined, color: colors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium aktiv',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text('Cloud-Funktionen sind für dein Konto verfügbar.'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),
            if (isLoading)
              const Row(
                children: [
                  SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Cloud-Status wird geladen ...'),
                ],
              )
            else if (error != null)
              Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Cloud-Status konnte nicht geladen werden.'),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Erneut')),
                ],
              )
            else
              Column(
                children: [
                  _CloudCountRow(
                    icon: Icons.directions_car_outlined,
                    text: cloudVehicleCount == 1
                        ? '1 Fahrzeug in der Cloud'
                        : '${cloudVehicleCount ?? 0} Fahrzeuge in der Cloud',
                  ),
                  const SizedBox(height: 14),
                  _CloudCountRow(
                    icon: Icons.local_gas_station_outlined,
                    text: cloudFuelEntryCount == 1
                        ? '1 Tankvorgang in der Cloud'
                        : '${cloudFuelEntryCount ?? 0} Tankvorgänge in der Cloud',
                  ),
                  const SizedBox(height: 14),
                  _CloudCountRow(
                    icon: Icons.payments_outlined,
                    text: cloudExpenseCount == 1
                        ? '1 Kosteneintrag in der Cloud'
                        : '${cloudExpenseCount ?? 0} Kosteneinträge in der Cloud',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CloudCountRow extends StatelessWidget {
  const _CloudCountRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Icon(Icons.cloud_done_outlined, color: colors.primary),
      ],
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard({required this.onPremiumTap});

  final VoidCallback onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.surfaceContainerHighest,
                  child: const Icon(Icons.cloud_off_outlined),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MotorLog Free',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Cloud-Backup und Synchronisierung sind '
                        'Premium-Funktionen.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPremiumTap,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('MotorLog Premium ansehen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (showProgress)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudActionUnavailableCard extends StatelessWidget {
  const _CloudActionUnavailableCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.lock_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
