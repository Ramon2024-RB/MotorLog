import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
          'Datenschutz',
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
                    Icons.privacy_tip_outlined,
                    size: 34,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deine Daten in MotorLog',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hier erfährst du, welche Daten MotorLog verarbeitet '
                  'und wofür sie verwendet werden.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const _PrivacySection(
            title: '1. Allgemeines',
            text:
                'MotorLog ist eine Anwendung zur Verwaltung von Fahrzeugen '
                'und den damit verbundenen Informationen. Dazu gehören '
                'beispielsweise Tankvorgänge, Kosten, Wartungen, Reifen '
                'und Fahrzeugdokumente.\n\n'
                'Der Schutz deiner persönlichen Daten ist wichtig. '
                'MotorLog verarbeitet nur Daten, die für die angebotenen '
                'Funktionen erforderlich sind.',
          ),

          const _PrivacySection(
            title: '2. Benutzerkonto',
            text:
                'Für Funktionen, die ein Benutzerkonto benötigen, werden '
                'Kontodaten verarbeitet. Dazu gehört insbesondere die für '
                'die Anmeldung verwendete E-Mail-Adresse.\n\n'
                'Die Anmeldung und Verwaltung des Benutzerkontos erfolgt '
                'über den von MotorLog eingesetzten Backend-Dienst.',
          ),

          const _PrivacySection(
            title: '3. Fahrzeugdaten',
            text:
                'MotorLog verarbeitet die von dir eingegebenen Daten zu '
                'deinen Fahrzeugen. Dazu können unter anderem '
                'Fahrzeugbezeichnung, Hersteller, Modell, Baujahr, '
                'Kilometerstand, Kennzeichen und Kraftstoffart gehören.\n\n'
                'Zusätzlich können Daten zu Tankvorgängen, Kosten, '
                'Wartungen, Reifen und Dokumenten gespeichert werden.',
          ),

          const _PrivacySection(
            title: '4. Lokale Speicherung',
            text:
                'MotorLog speichert Fahrzeug- und Nutzungsdaten lokal auf '
                'deinem Gerät. Dadurch können wesentliche Funktionen der '
                'App auch mit lokal gespeicherten Daten verwendet werden.\n\n'
                'Die lokal gespeicherten Daten sind grundsätzlich dem '
                'jeweiligen angemeldeten Benutzer zugeordnet.',
          ),

          const _PrivacySection(
            title: '5. Cloud-Sicherung',
            text:
                'Wenn du die Cloud-Funktionen von MotorLog verwendest, '
                'können ausgewählte App-Daten zur Sicherung und '
                'Wiederherstellung an den verwendeten Cloud-Dienst '
                'übertragen werden.\n\n'
                'Die Cloud-Sicherung dient dazu, deine MotorLog-Daten '
                'beispielsweise nach einem Gerätewechsel oder einer '
                'Neuinstallation wiederherstellen zu können.',
          ),

          const _PrivacySection(
            title: '6. Benachrichtigungen',
            text:
                'MotorLog kann lokale Benachrichtigungen verwenden, um '
                'dich beispielsweise an anstehende Wartungstermine oder '
                'erreichte Kilometerstände zu erinnern.\n\n'
                'Benachrichtigungen können innerhalb von MotorLog '
                'eingestellt und zusätzlich über die Systemeinstellungen '
                'deines Geräts verwaltet werden.',
          ),

          const _PrivacySection(
            title: '7. Berechtigungen',
            text:
                'MotorLog kann für bestimmte Funktionen '
                'Geräteberechtigungen benötigen. Eine Berechtigung wird '
                'nur verwendet, wenn sie für die entsprechende Funktion '
                'notwendig ist.\n\n'
                'Du kannst erteilte Berechtigungen jederzeit über die '
                'Systemeinstellungen deines Geräts ändern oder entziehen.',
          ),

          const _PrivacySection(
            title: '8. Löschung deiner Daten',
            text:
                'Lokal gespeicherte Daten können durch entsprechende '
                'Funktionen innerhalb der App entfernt werden.\n\n'
                'Für Daten, die mit einem MotorLog-Konto oder einer '
                'Cloud-Sicherung verbunden sind, werden vor der '
                'Veröffentlichung der App zusätzliche Möglichkeiten zur '
                'Kontoverwaltung und Datenlöschung bereitgestellt.',
          ),

          const _PrivacySection(
            title: '9. Änderungen dieser Hinweise',
            text:
                'Diese Datenschutzhinweise können angepasst werden, wenn '
                'neue Funktionen zu MotorLog hinzukommen oder sich die '
                'Art der Datenverarbeitung verändert.',
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
                    'Hinweis: Diese Datenschutzhinweise befinden sich '
                    'während der Entwicklung von MotorLog noch in '
                    'Bearbeitung. Vor einer öffentlichen Veröffentlichung '
                    'wird die endgültige Datenschutzerklärung ergänzt und '
                    'rechtlich geprüft.',
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

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.text});

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
