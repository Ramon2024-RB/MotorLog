import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/premium_provider.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  bool _yearlySelected = true;
  bool _isActivatingPremium = false;

  Future<void> _activatePremiumForTesting() async {
    if (_isActivatingPremium) {
      return;
    }

    final shouldActivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.science_outlined),
          title: const Text('Premium testen?'),
          content: const Text(
            'Damit wird MotorLog Premium für dieses Testkonto '
            'freigeschaltet.\n\n'
            'Es findet kein echter Kauf und keine Zahlung statt.',
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
              child: const Text('Premium testen'),
            ),
          ],
        );
      },
    );

    if (shouldActivate != true || !mounted) {
      return;
    }

    setState(() {
      _isActivatingPremium = true;
    });

    try {
      await ref.read(premiumProvider.notifier).activatePremiumForTesting();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MotorLog Premium wurde für dein Testkonto aktiviert.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Premium konnte nicht aktiviert werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActivatingPremium = false;
        });
      }
    }
  }

  void _showRestoreComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Die Wiederherstellung echter Käufe verbinden wir später '
          'mit dem App Store und Google Play.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final premiumAsync = ref.watch(premiumProvider);

    final isPremium = premiumAsync.value ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Zurück',
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'MotorLog Premium',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colors.primary,
                    child: Icon(
                      Icons.workspace_premium,
                      size: 40,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isPremium
                        ? 'Du hast MotorLog Premium'
                        : 'Mehr aus MotorLog herausholen',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isPremium
                        ? 'Premium ist für dein MotorLog-Konto aktiviert.'
                        : 'Verwalte mehrere Fahrzeuge, sichere deine Daten '
                              'in der Cloud und erhalte noch mehr Einblicke in '
                              'deine Fahrzeugkosten.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Premium-Vorteile',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            const _PremiumFeatureCard(
              icon: Icons.directions_car_outlined,
              title: 'Mehrere Fahrzeuge',
              description:
                  'Verwalte Autos, Motorräder, Camper und weitere Fahrzeuge '
                  'gemeinsam in MotorLog.',
            ),

            const SizedBox(height: 12),

            const _PremiumFeatureCard(
              icon: Icons.cloud_done_outlined,
              title: 'Cloud-Backup',
              description:
                  'Sichere deine MotorLog-Daten und schütze sie bei einem '
                  'Gerätewechsel oder Verlust.',
            ),

            const SizedBox(height: 12),

            const _PremiumFeatureCard(
              icon: Icons.sync,
              title: 'Synchronisierung',
              description:
                  'Halte deine MotorLog-Daten auf mehreren Geräten '
                  'automatisch auf dem gleichen Stand.',
            ),

            const SizedBox(height: 12),

            const _PremiumFeatureCard(
              icon: Icons.bar_chart_outlined,
              title: 'Erweiterte Statistiken',
              description:
                  'Erhalte zusätzliche Auswertungen zu Verbrauch, '
                  'Fahrzeugkosten und Entwicklung.',
            ),

            const SizedBox(height: 12),

            const _PremiumFeatureCard(
              icon: Icons.description_outlined,
              title: 'Dokumente',
              description:
                  'Verwalte wichtige Fahrzeugunterlagen direkt bei '
                  'deinem Fahrzeug.',
            ),

            const SizedBox(height: 12),

            const _PremiumFeatureCard(
              icon: Icons.file_download_outlined,
              title: 'Datenexport',
              description:
                  'Exportiere deine Fahrzeugdaten später bequem als '
                  'PDF oder CSV.',
            ),

            const SizedBox(height: 32),

            Text(
              'Free oder Premium?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            const _ComparisonCard(),

            const SizedBox(height: 32),

            if (isPremium) ...[
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: colors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primary,
                        child: Icon(Icons.check, color: colors.onPrimary),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium aktiv',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Alle Premium-Funktionen sind für '
                              'dieses Konto freigeschaltet.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Premium wählen',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Die endgültigen Preise werden später direkt aus dem '
                'App Store bzw. Google Play geladen.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),

              const SizedBox(height: 14),

              _PlanCard(
                title: 'Jährlich',
                subtitle: '12 Monate MotorLog Premium',
                badge: 'Beste Wahl',
                selected: _yearlySelected,
                onTap: () {
                  setState(() {
                    _yearlySelected = true;
                  });
                },
              ),

              const SizedBox(height: 12),

              _PlanCard(
                title: 'Monatlich',
                subtitle: 'Flexibel monatlich',
                selected: !_yearlySelected,
                onTap: () {
                  setState(() {
                    _yearlySelected = false;
                  });
                },
              ),

              const SizedBox(height: 22),

              FilledButton.icon(
                onPressed: _isActivatingPremium
                    ? null
                    : _activatePremiumForTesting,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _isActivatingPremium
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.science_outlined),
                label: Text(
                  _isActivatingPremium
                      ? 'Premium wird aktiviert ...'
                      : 'Premium testweise freischalten',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextButton(
                onPressed: _showRestoreComingSoon,
                child: const Text('Käufe wiederherstellen'),
              ),

              const SizedBox(height: 8),

              Text(
                'Testmodus: Es findet aktuell kein echter Kauf statt. '
                'Vor der Veröffentlichung wird diese Funktion durch '
                'die Abonnements des App Store und Google Play ersetzt.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumFeatureCard extends StatelessWidget {
  const _PremiumFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Column(
        children: [
          _ComparisonHeader(),
          Divider(height: 1),
          _ComparisonRow(title: '1 Fahrzeug', free: true, premium: true),
          Divider(height: 1),
          _ComparisonRow(title: 'Tanken & Kosten', free: true, premium: true),
          Divider(height: 1),
          _ComparisonRow(title: 'Wartungen', free: true, premium: true),
          Divider(height: 1),
          _ComparisonRow(
            title: 'Mehrere Fahrzeuge',
            free: false,
            premium: true,
          ),
          Divider(height: 1),
          _ComparisonRow(title: 'Cloud-Backup', free: false, premium: true),
          Divider(height: 1),
          _ComparisonRow(title: 'Synchronisierung', free: false, premium: true),
          Divider(height: 1),
          _ComparisonRow(
            title: 'Erweiterte Statistiken',
            free: false,
            premium: true,
          ),
          Divider(height: 1),
          _ComparisonRow(title: 'Datenexport', free: false, premium: true),
        ],
      ),
    );
  }
}

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Funktion',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.title,
    required this.free,
    required this.premium,
  });

  final String title;
  final bool free;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget statusIcon(bool enabled) {
      return Icon(
        enabled ? Icons.check_circle : Icons.remove_circle_outline,
        size: 21,
        color: enabled ? colors.primary : colors.onSurfaceVariant,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Center(child: statusIcon(free))),
          Expanded(child: Center(child: statusIcon(premium))),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
