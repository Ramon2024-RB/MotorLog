import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
          'Hilfe & FAQ',
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
                    Icons.help_outline,
                    size: 36,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wie können wir helfen?',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hier findest du Antworten auf häufige Fragen '
                  'rund um MotorLog.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          const _FaqSectionTitle(icon: Icons.person_outline, title: 'Konto'),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Warum benötige ich ein MotorLog-Konto?',
                answer:
                    'Dein Konto ermöglicht es MotorLog, deine lokalen Daten '
                    'dem richtigen Benutzer zuzuordnen. Außerdem wird das '
                    'Konto für Funktionen wie die Cloud-Sicherung und '
                    'Wiederherstellung benötigt.',
              ),
              _FaqItem(
                question: 'Was passiert, wenn ich mich abmelde?',
                answer:
                    'Beim Abmelden wird dein aktuelles Benutzerkonto in '
                    'MotorLog geschlossen. Daten anderer MotorLog-Konten '
                    'werden getrennt voneinander verwaltet.',
              ),
              _FaqItem(
                question: 'Ich habe mein Passwort vergessen. Was kann ich tun?',
                answer:
                    'Auf der Anmeldeseite kannst du die Funktion zum '
                    'Zurücksetzen deines Passworts verwenden. Folge danach '
                    'den Anweisungen, die dir für die Wiederherstellung '
                    'deines Kontos angezeigt werden.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.directions_car_outlined,
            title: 'Fahrzeuge',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Welche Fahrzeuge kann ich in MotorLog speichern?',
                answer:
                    'MotorLog unterstützt verschiedene Fahrzeugtypen wie '
                    'Autos, Camper und Motorräder. Zu einem Fahrzeug können '
                    'unter anderem Hersteller, Modell, Baujahr, '
                    'Kilometerstand, Kennzeichen und Kraftstoffart '
                    'gespeichert werden.',
              ),
              _FaqItem(
                question: 'Was ist das Standardfahrzeug?',
                answer:
                    'Das Standardfahrzeug ist das Fahrzeug, das MotorLog '
                    'bevorzugt verwendet, wenn mehrere Fahrzeuge in deinem '
                    'Konto vorhanden sind.',
              ),
              _FaqItem(
                question: 'Wird mein Kilometerstand automatisch aktualisiert?',
                answer:
                    'Bei bestimmten Einträgen kann MotorLog einen neu '
                    'eingetragenen höheren Kilometerstand übernehmen. '
                    'Dadurch bleibt der aktuelle Kilometerstand des '
                    'Fahrzeugs leichter auf dem neuesten Stand.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.local_gas_station_outlined,
            title: 'Tanken & Kosten',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Was kann ich bei einem Tankvorgang speichern?',
                answer:
                    'Tankvorgänge können einem Fahrzeug zugeordnet werden. '
                    'Die gespeicherten Angaben werden anschließend für die '
                    'Übersicht und Auswertungen des Fahrzeugs verwendet.',
              ),
              _FaqItem(
                question: 'Welche Kosten kann ich erfassen?',
                answer:
                    'MotorLog ermöglicht dir, fahrzeugbezogene Ausgaben zu '
                    'speichern und einem Fahrzeug zuzuordnen. So kannst du '
                    'deine laufenden Fahrzeugkosten übersichtlich '
                    'dokumentieren.',
              ),
              _FaqItem(
                question: 'Wo finde ich meine Auswertungen?',
                answer:
                    'Die Fahrzeugstatistiken findest du über das jeweilige '
                    'Fahrzeug beziehungsweise die dafür vorgesehene '
                    'Statistikansicht in MotorLog.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.build_outlined,
            title: 'Wartungen',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Kann MotorLog mich an Wartungen erinnern?',
                answer:
                    'Ja. MotorLog kann dich abhängig von deinen Einstellungen '
                    'an Wartungstermine und bestimmte Kilometerstände '
                    'erinnern.',
              ),
              _FaqItem(
                question: 'Warum bekomme ich keine Wartungserinnerung?',
                answer:
                    'Prüfe unter Einstellungen → Benachrichtigungen, ob die '
                    'Wartungserinnerungen aktiviert sind. Zusätzlich müssen '
                    'Benachrichtigungen für MotorLog in den '
                    'Systemeinstellungen deines Geräts erlaubt sein.',
              ),
              _FaqItem(
                question: 'Ersetzt eine MotorLog-Erinnerung eine Werkstatt?',
                answer:
                    'Nein. Die Erinnerungen dienen als organisatorische '
                    'Unterstützung. Wartungsbedarf und Verkehrssicherheit '
                    'sollten weiterhin fachgerecht geprüft werden.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.tire_repair_outlined,
            title: 'Reifen & Dokumente',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Kann ich meine Reifensätze verwalten?',
                answer:
                    'Ja. MotorLog bietet eine Reifenverwaltung, mit der '
                    'Reifeninformationen einem Fahrzeug zugeordnet werden '
                    'können.',
              ),
              _FaqItem(
                question: 'Kann ich Fahrzeugdokumente speichern?',
                answer:
                    'Ja. Über die Dokumentenverwaltung kannst du '
                    'fahrzeugbezogene Dokumente beziehungsweise deren '
                    'Informationen innerhalb von MotorLog verwalten.',
              ),
              _FaqItem(
                question: 'Sollte ich wichtige Originaldokumente behalten?',
                answer:
                    'Ja. MotorLog dient der digitalen Organisation deiner '
                    'Fahrzeugdaten. Gesetzlich oder praktisch erforderliche '
                    'Originaldokumente solltest du unabhängig davon sicher '
                    'aufbewahren.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.cloud_outlined,
            title: 'Cloud & Datensicherung',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Was macht die Cloud-Sicherung?',
                answer:
                    'Mit der Cloud-Sicherung können unterstützte '
                    'MotorLog-Daten online gesichert werden. Dadurch können '
                    'sie beispielsweise nach einer Neuinstallation oder '
                    'einem Gerätewechsel wiederhergestellt werden.',
              ),
              _FaqItem(
                question: 'Sind meine lokalen Daten automatisch ein Backup?',
                answer:
                    'Nein. Daten, die ausschließlich auf deinem Gerät '
                    'gespeichert sind, sind keine unabhängige Sicherung. '
                    'Wenn dir deine Daten wichtig sind, solltest du die '
                    'verfügbaren Sicherungsfunktionen verwenden.',
              ),
              _FaqItem(
                question: 'Wie stelle ich meine Daten wieder her?',
                answer:
                    'Öffne Einstellungen → Cloud & Synchronisierung. Dort '
                    'kannst du die verfügbaren Funktionen zur '
                    'Wiederherstellung deiner gesicherten MotorLog-Daten '
                    'verwenden.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.workspace_premium_outlined,
            title: 'MotorLog Premium',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Was ist MotorLog Premium?',
                answer:
                    'MotorLog Premium ist für zusätzliche Funktionen und '
                    'Leistungen vorgesehen, die über die grundlegende '
                    'Nutzung von MotorLog hinausgehen.',
              ),
              _FaqItem(
                question: 'Welche Funktionen gehören zu Premium?',
                answer:
                    'Der genaue Premium-Umfang wird dir innerhalb von '
                    'MotorLog angezeigt. Der Funktionsumfang kann sich '
                    'während der Weiterentwicklung der App noch verändern.',
              ),
              _FaqItem(
                question: 'Brauche ich Premium, um MotorLog zu nutzen?',
                answer:
                    'Nein. MotorLog ist so ausgelegt, dass grundlegende '
                    'Fahrzeugfunktionen auch ohne Premium sinnvoll genutzt '
                    'werden können.',
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _FaqSectionTitle(
            icon: Icons.notifications_outlined,
            title: 'Benachrichtigungen',
          ),

          const SizedBox(height: 12),

          const _FaqCard(
            questions: [
              _FaqItem(
                question: 'Wo kann ich Benachrichtigungen einstellen?',
                answer:
                    'Öffne Profil & Einstellungen → Benachrichtigungen. '
                    'Dort kannst du die verfügbaren MotorLog-Erinnerungen '
                    'ein- oder ausschalten.',
              ),
              _FaqItem(
                question: 'Kann ich Benachrichtigungen komplett deaktivieren?',
                answer:
                    'Ja. Du kannst die MotorLog-Erinnerungen innerhalb der '
                    'App deaktivieren. Zusätzlich kannst du '
                    'Benachrichtigungen über die Systemeinstellungen deines '
                    'Geräts verwalten.',
              ),
            ],
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
                Icon(
                  Icons.support_agent_outlined,
                  color: colors.primary,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  'Deine Frage ist nicht dabei?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Weitere Hilfe findest du im Bereich '
                  '„Kontakt & Support“.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSectionTitle extends StatelessWidget {
  const _FaqSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.questions});

  final List<_FaqItem> questions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          for (var index = 0; index < questions.length; index++) ...[
            _FaqTile(item: questions[index]),
            if (index < questions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
