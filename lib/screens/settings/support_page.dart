import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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
              context.go('/settings/about');
            }
          },
        ),
        title: const Text(
          'Kontakt & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
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
                    Icons.support_agent_outlined,
                    size: 36,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wir helfen dir weiter',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Du hast ein Problem, eine Frage oder eine Idee '
                  'für MotorLog? Hier findest du die passenden '
                  'Kontaktmöglichkeiten.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const _SectionTitle(title: 'Wobei können wir helfen?'),

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
                _SupportTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Problem melden',
                  subtitle: 'Etwas funktioniert nicht wie erwartet',
                  onTap: () {
                    _showContactInfo(
                      context,
                      title: 'Problem melden',
                      icon: Icons.bug_report_outlined,
                      description:
                          'Beschreibe möglichst genau, was passiert ist '
                          'und welche Schritte zu dem Problem geführt haben.',
                      additionalInfo:
                          'Hilfreich sind außerdem deine MotorLog-Version, '
                          'dein Gerät und die verwendete '
                          'Betriebssystemversion.',
                    );
                  },
                ),
                const Divider(height: 1),
                _SupportTile(
                  icon: Icons.lightbulb_outline,
                  title: 'Idee & Verbesserung',
                  subtitle: 'Wünsche oder Vorschläge für MotorLog',
                  onTap: () {
                    _showContactInfo(
                      context,
                      title: 'Idee & Verbesserung',
                      icon: Icons.lightbulb_outline,
                      description:
                          'Du hast eine Idee für eine neue Funktion oder '
                          'möchtest etwas an MotorLog verbessern?',
                      additionalInfo:
                          'Beschreibe deine Idee und am besten auch, '
                          'welches Problem sie für dich lösen würde.',
                    );
                  },
                ),
                const Divider(height: 1),
                _SupportTile(
                  icon: Icons.help_outline,
                  title: 'Allgemeine Frage',
                  subtitle: 'Fragen zur Bedienung oder zu MotorLog',
                  onTap: () {
                    _showContactInfo(
                      context,
                      title: 'Allgemeine Frage',
                      icon: Icons.help_outline,
                      description:
                          'Bei Fragen zur Nutzung von MotorLog kannst du '
                          'dich ebenfalls an den Support wenden.',
                      additionalInfo:
                          'Schau vorher gerne auch in Hilfe & FAQ. '
                          'Dort findest du bereits Antworten auf viele '
                          'häufige Fragen.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle(title: 'Vor einer Problemmeldung'),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                _TipRow(
                  number: '1',
                  text: 'Prüfe, ob MotorLog auf dem aktuellen Stand ist.',
                ),
                SizedBox(height: 18),
                _TipRow(
                  number: '2',
                  text:
                      'Schließe MotorLog vollständig und öffne die App erneut.',
                ),
                SizedBox(height: 18),
                _TipRow(
                  number: '3',
                  text:
                      'Prüfe bei Benachrichtigungsproblemen zusätzlich '
                      'die Systemeinstellungen deines Geräts.',
                ),
                SizedBox(height: 18),
                _TipRow(
                  number: '4',
                  text:
                      'Notiere möglichst genau, wann und bei welcher '
                      'Aktion das Problem auftritt.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const _SectionTitle(title: 'App-Informationen'),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                _InfoTile(
                  icon: Icons.apps_outlined,
                  title: 'App',
                  subtitle: 'MotorLog',
                ),
                Divider(height: 1),
                _InfoTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '$_version ($_buildNumber)',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(Icons.mail_outline, size: 30, color: colors.primary),
                const SizedBox(height: 10),
                Text(
                  'Direkter Kontakt',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die offizielle Support-E-Mail-Adresse wird vor der '
                  'Veröffentlichung von MotorLog hier hinterlegt.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Der direkte E-Mail-Support wird vor der '
                          'Veröffentlichung eingerichtet.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Support kontaktieren'),
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

  static Future<void> _showContactInfo(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required String additionalInfo,
  }) {
    final colors = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(icon, color: colors.primary, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  additionalInfo,
                  textAlign: TextAlign.center,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Die Support-Kontaktfunktion wird vor der '
                            'Veröffentlichung eingerichtet.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Support kontaktieren'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _SupportTile extends StatelessWidget {
  const _SupportTile({
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

class _TipRow extends StatelessWidget {
  const _TipRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: colors.primaryContainer,
          child: Text(
            number,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
