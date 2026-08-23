import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
          'Nutzungsbedingungen',
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
                    Icons.gavel_outlined,
                    size: 34,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nutzung von MotorLog',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Diese Bedingungen beschreiben die grundlegenden Regeln '
                  'für die Nutzung von MotorLog.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const _TermsSection(
            title: '1. Geltungsbereich',
            text:
                'Diese Nutzungsbedingungen gelten für die Verwendung der '
                'Anwendung MotorLog.\n\n'
                'MotorLog dient der persönlichen Verwaltung von Fahrzeugen '
                'und damit verbundenen Informationen.',
          ),

          const _TermsSection(
            title: '2. Funktionen von MotorLog',
            text:
                'MotorLog stellt Funktionen zur Verwaltung von '
                'Fahrzeugdaten bereit. Dazu können insbesondere '
                'Fahrzeuge, Tankvorgänge, Kosten, Wartungen, Reifen, '
                'Dokumente und Statistiken gehören.\n\n'
                'Der Funktionsumfang kann im Laufe der Weiterentwicklung '
                'der App verändert oder erweitert werden.',
          ),

          const _TermsSection(
            title: '3. Benutzerkonto',
            text:
                'Für bestimmte Funktionen von MotorLog ist ein '
                'Benutzerkonto erforderlich.\n\n'
                'Nutzer sind dafür verantwortlich, ihre Zugangsdaten '
                'vertraulich zu behandeln und den Zugang zum eigenen '
                'Benutzerkonto angemessen zu schützen.',
          ),

          const _TermsSection(
            title: '4. Eingetragene Daten',
            text:
                'Die in MotorLog gespeicherten Fahrzeug- und '
                'Nutzungsdaten werden grundsätzlich durch den Nutzer '
                'selbst eingegeben oder verwaltet.\n\n'
                'Der Nutzer ist dafür verantwortlich, die Richtigkeit '
                'und Aktualität der eingetragenen Informationen zu prüfen.',
          ),

          const _TermsSection(
            title: '5. Wartungen und Erinnerungen',
            text:
                'MotorLog kann Wartungsintervalle, Termine, '
                'Kilometerstände und Erinnerungen anzeigen.\n\n'
                'Diese Funktionen dienen ausschließlich als '
                'Unterstützung. MotorLog ersetzt keine fachgerechte '
                'Prüfung, Wartung oder Beurteilung eines Fahrzeugs durch '
                'eine qualifizierte Fachperson oder Werkstatt.',
          ),

          const _TermsSection(
            title: '6. Benachrichtigungen',
            text:
                'Benachrichtigungen und Erinnerungen können von '
                'Geräteeinstellungen, Betriebssystemfunktionen und '
                'technischen Einschränkungen abhängig sein.\n\n'
                'Nutzer sollten sich daher bei sicherheitsrelevanten oder '
                'gesetzlich vorgeschriebenen Terminen nicht ausschließlich '
                'auf Benachrichtigungen von MotorLog verlassen.',
          ),

          const _TermsSection(
            title: '7. Cloud-Sicherung',
            text:
                'Soweit MotorLog Cloud-Funktionen anbietet, können Daten '
                'zur Sicherung und Wiederherstellung mit dem verwendeten '
                'Cloud-Dienst synchronisiert werden.\n\n'
                'Trotz technischer Schutzmaßnahmen kann eine vollständig '
                'unterbrechungs- oder fehlerfreie Verfügbarkeit von '
                'Cloud-Diensten nicht garantiert werden.',
          ),

          const _TermsSection(
            title: '8. Premium-Funktionen',
            text:
                'MotorLog kann zusätzliche Funktionen oder Leistungen im '
                'Rahmen einer Premium-Version anbieten.\n\n'
                'Welche Funktionen Bestandteil der kostenlosen oder '
                'kostenpflichtigen Version sind, ergibt sich aus der '
                'jeweils aktuellen Beschreibung innerhalb der App oder '
                'des jeweiligen App-Stores.',
          ),

          const _TermsSection(
            title: '9. Verfügbarkeit',
            text:
                'Es wird angestrebt, MotorLog zuverlässig bereitzustellen. '
                'Eine jederzeitige und vollständig störungsfreie '
                'Verfügbarkeit kann jedoch nicht zugesichert werden.\n\n'
                'Insbesondere Wartungsarbeiten, technische Probleme oder '
                'Störungen externer Dienste können die Verfügbarkeit '
                'einzelner Funktionen beeinflussen.',
          ),

          const _TermsSection(
            title: '10. Eigenverantwortung',
            text:
                'MotorLog ist ein Werkzeug zur Organisation und '
                'Dokumentation von Fahrzeugdaten.\n\n'
                'Entscheidungen über Wartung, Reparatur, Betrieb oder '
                'Verkehrssicherheit eines Fahrzeugs liegen weiterhin in '
                'der Verantwortung des Fahrzeughalters beziehungsweise '
                'Nutzers.',
          ),

          const _TermsSection(
            title: '11. Unzulässige Nutzung',
            text:
                'MotorLog darf nicht missbräuchlich oder für rechtswidrige '
                'Zwecke verwendet werden.\n\n'
                'Insbesondere dürfen technische Schutzmaßnahmen, '
                'Zugriffsbeschränkungen oder Sicherheitsmechanismen der '
                'App nicht gezielt umgangen oder manipuliert werden.',
          ),

          const _TermsSection(
            title: '12. Änderungen',
            text:
                'MotorLog wird fortlaufend weiterentwickelt. Funktionen '
                'und diese Nutzungsbedingungen können deshalb angepasst '
                'werden, wenn dies aufgrund technischer, rechtlicher oder '
                'funktionaler Änderungen erforderlich ist.',
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hinweis: Diese Nutzungsbedingungen befinden sich '
                    'während der Entwicklung von MotorLog noch in '
                    'Bearbeitung. Vor einer öffentlichen Veröffentlichung '
                    'werden die endgültigen Bedingungen an den tatsächlichen '
                    'Funktionsumfang, das Geschäftsmodell und die '
                    'rechtlichen Anforderungen angepasst und geprüft.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Stand: August 2026',
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

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
