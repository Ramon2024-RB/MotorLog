import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/cloud_sync_service.dart';
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
  bool _isRestoring = false;

  int? _cloudVehicleCount;
  String? _cloudStatusError;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadCloudStatus);
  }

  Future<void> _loadCloudStatus() async {
    if (!mounted) {
      return;
    }

    final premiumValue = ref.read(premiumProvider).asData?.value;

    if (premiumValue != true) {
      setState(() {
        _cloudVehicleCount = null;
        _cloudStatusError = null;
        _isLoadingCloudStatus = false;
      });

      return;
    }

    setState(() {
      _isLoadingCloudStatus = true;
      _cloudStatusError = null;
    });

    try {
      final count = await _cloudSyncService.getCloudVehicleCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _cloudVehicleCount = count;
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

  Future<void> _restoreVehicles() async {
    if (_isRestoring) {
      return;
    }

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.cloud_download_outlined),
          title: const Text('Fahrzeuge wiederherstellen?'),
          content: const Text(
            'Die in deiner MotorLog Cloud gespeicherten Fahrzeuge werden '
            'auf dieses Gerät übertragen.\n\n'
            'Fahrzeuge mit derselben ID werden aktualisiert. Andere lokale '
            'Fahrzeuge werden dabei nicht gelöscht.',
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
      final restoredCount = await ref
          .read(vehicleProvider.notifier)
          .restoreVehiclesFromCloud();

      if (!mounted) {
        return;
      }

      setState(() {
        _isRestoring = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            restoredCount == 1
                ? '1 Fahrzeug wurde aus der Cloud wiederhergestellt.'
                : '$restoredCount Fahrzeuge wurden aus der Cloud '
                      'wiederhergestellt.',
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
                  error: _cloudStatusError,
                  onRetry: _loadCloudStatus,
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
                return const _RestoreUnavailableCard(
                  text: 'Tarif wird geladen ...',
                );
              },
              error: (error, stackTrace) {
                return const _RestoreUnavailableCard(
                  text: 'Cloud-Funktion momentan nicht verfügbar.',
                );
              },
              data: (isPremium) {
                if (!isPremium) {
                  return const _RestoreUnavailableCard(
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
                                    'Fahrzeuge wiederherstellen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Lade deine gespeicherten Fahrzeuge '
                                    'aus der MotorLog Cloud.',
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
                            onPressed: _isRestoring ? null : _restoreVehicles,
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
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final int? cloudVehicleCount;
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
              Row(
                children: [
                  Icon(Icons.directions_car_outlined, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cloudVehicleCount == 1
                          ? '1 Fahrzeug in der Cloud'
                          : '${cloudVehicleCount ?? 0} Fahrzeuge in der Cloud',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.cloud_done_outlined, color: colors.primary),
                ],
              ),
          ],
        ),
      ),
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

class _RestoreUnavailableCard extends StatelessWidget {
  const _RestoreUnavailableCard({required this.text});

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
