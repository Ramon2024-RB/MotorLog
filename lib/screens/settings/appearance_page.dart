import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/theme_provider.dart';

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final themeAsync = ref.watch(themeProvider);
    final selectedTheme = themeAsync.value ?? ThemeMode.system;

    Future<void> selectTheme(ThemeMode themeMode) async {
      await ref.read(themeProvider.notifier).setThemeMode(themeMode);
    }

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
          'Darstellung',
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
                    Icons.palette_outlined,
                    size: 34,
                    color: colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MotorLog nach deinem Geschmack',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wähle, ob MotorLog dem Design deines Geräts folgen '
                  'oder immer hell bzw. dunkel dargestellt werden soll.',
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
            'Design',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            title: 'Systemstandard',
            subtitle: 'Folgt automatisch der Einstellung deines Geräts',
            selected: selectedTheme == ThemeMode.system,
            onTap: () => selectTheme(ThemeMode.system),
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            title: 'Hell',
            subtitle: 'MotorLog immer im hellen Design verwenden',
            selected: selectedTheme == ThemeMode.light,
            onTap: () => selectTheme(ThemeMode.light),
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            title: 'Dunkel',
            subtitle: 'MotorLog immer im dunklen Design verwenden',
            selected: selectedTheme == ThemeMode.dark,
            onTap: () => selectTheme(ThemeMode.dark),
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
                      'Die Auswahl wird auf diesem Gerät gespeichert '
                      'und bleibt auch nach einem Neustart von MotorLog erhalten.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

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
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: selected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                child: Icon(
                  icon,
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
