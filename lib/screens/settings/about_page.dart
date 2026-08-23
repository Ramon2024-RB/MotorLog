import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _version = '1.0.0';
  static const String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          'Über MotorLog',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _AppHeader(colors: colors),

          const SizedBox(height: 30),

          const _SectionTitle(title: 'App'),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                const _InfoTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '$_version ($_buildNumber)',
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.description_outlined,
                  title: 'Open-Source-Lizenzen',
                  subtitle: 'Verwendete Software und Lizenzen',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'MotorLog',
                      applicationVersion: _version,
                      applicationLegalese: '© 2026 MotorLog',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle(title: 'Rechtliches'),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Datenschutz',
                  subtitle: 'Informationen zum Schutz deiner Daten',
                  onTap: () {
                    context.push('/settings/about/privacy');
                  },
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.gavel_outlined,
                  title: 'Nutzungsbedingungen',
                  subtitle: 'Bedingungen für die Nutzung von MotorLog',
                  onTap: () {
                    context.push('/settings/about/terms');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle(title: 'Hilfe'),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.help_outline,
                  title: 'Hilfe & FAQ',
                  subtitle: 'Antworten auf häufige Fragen',
                  onTap: () {
                    context.push('/settings/about/faq');
                  },
                ),
                const Divider(height: 1),
                _ActionTile(
                  icon: Icons.mail_outline,
                  title: 'Kontakt & Support',
                  subtitle: 'Hilfe bei Problemen mit MotorLog',
                  onTap: () {
                    context.push('/settings/about/support');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(Icons.favorite_outline, color: colors.primary, size: 28),
                const SizedBox(height: 10),
                Text(
                  'Danke, dass du MotorLog nutzt.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'MotorLog soll dir dabei helfen, deine Fahrzeuge, '
                  'Tankvorgänge, Kosten, Wartungen, Reifen und Dokumente '
                  'einfach an einem Ort im Blick zu behalten.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'MotorLog · Version $_version',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 48,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'MotorLog',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dein digitales Fahrzeug-Logbuch',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(icon, color: colors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(icon, color: colors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
