import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/premium_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSigningOut = false;

  SupabaseClient get _supabase => Supabase.instance.client;

  User? get _user => _supabase.auth.currentUser;

  String get _email {
    final email = _user?.email;

    if (email == null || email.trim().isEmpty) {
      return 'Keine E-Mail-Adresse';
    }

    return email;
  }

  String get _initial {
    final email = _user?.email?.trim();

    if (email == null || email.isEmpty) {
      return 'M';
    }

    return email.substring(0, 1).toUpperCase();
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout),
          title: const Text('Abmelden?'),
          content: const Text(
            'Möchtest du dich wirklich von deinem MotorLog-Konto abmelden?',
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
              child: const Text('Abmelden'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true || !mounted) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _supabase.auth.signOut();
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abmelden fehlgeschlagen: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSigningOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abmelden fehlgeschlagen: $error')),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature bauen wir in einem der nächsten Schritte ein.'),
      ),
    );
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
            context.go('/');
          },
        ),
        title: const Text(
          'Profil & Einstellungen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return ref.read(premiumProvider.notifier).reload();
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colors.primary,
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MotorLog Konto',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const _SectionTitle(title: 'Dein Tarif'),

            const SizedBox(height: 12),

            premiumAsync.when(
              loading: () => const _PremiumLoadingCard(),
              error: (error, stackTrace) {
                return _PremiumErrorCard(
                  onRetry: () {
                    ref.read(premiumProvider.notifier).reload();
                  },
                );
              },
              data: (isPremium) {
                return _PremiumCard(
                  isPremium: isPremium,
                  onTap: () {
                    context.push('/premium');
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            const _SectionTitle(title: 'Konto'),

            const SizedBox(height: 12),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Kontodaten',
                  subtitle: _email,
                  onTap: () {
                    _showComingSoon('Kontodaten');
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.cloud_outlined,
                  title: 'Cloud & Synchronisierung',
                  subtitle: 'Backup und Synchronisierung verwalten',
                  onTap: () {
                    context.push('/settings/cloud');
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _SectionTitle(title: 'App'),

            const SizedBox(height: 12),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Benachrichtigungen',
                  subtitle: 'Erinnerungen und Hinweise verwalten',
                  onTap: () {
                    _showComingSoon('Benachrichtigungseinstellungen');
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Darstellung',
                  subtitle: 'Design und Erscheinungsbild',
                  onTap: () {
                    _showComingSoon('Darstellungseinstellungen');
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Über MotorLog',
                  subtitle: 'Version, Datenschutz und Informationen',
                  onTap: () {
                    _showComingSoon('Über MotorLog');
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _SectionTitle(title: 'Konto'),

            const SizedBox(height: 12),

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
                  backgroundColor: colors.errorContainer,
                  child: Icon(Icons.logout, color: colors.onErrorContainer),
                ),
                title: Text(
                  'Abmelden',
                  style: TextStyle(
                    color: colors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Von deinem MotorLog-Konto abmelden'),
                trailing: _isSigningOut
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _isSigningOut ? null : _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.isPremium, required this.onTap});

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: colors.primary,
                    child: Icon(
                      isPremium
                          ? Icons.workspace_premium
                          : Icons.workspace_premium_outlined,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'MotorLog Premium' : 'MotorLog Free',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isPremium
                              ? 'Premium ist für dein Konto aktiv'
                              : 'Du nutzt aktuell die kostenlose Version',
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),

              const SizedBox(height: 18),

              if (isPremium) ...[
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PremiumFeatureChip(
                      icon: Icons.verified_outlined,
                      label: 'Premium aktiv',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.cloud_done_outlined,
                      label: 'Cloud-Backup',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.sync,
                      label: 'Synchronisierung',
                    ),
                  ],
                ),
              ] else ...[
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PremiumFeatureChip(
                      icon: Icons.cloud_done_outlined,
                      label: 'Cloud-Backup',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.sync,
                      label: 'Synchronisierung',
                    ),
                    _PremiumFeatureChip(
                      icon: Icons.bar_chart_outlined,
                      label: 'Mehr Statistiken',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      Icons.lock_open_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Premium entdecken',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumLoadingCard extends StatelessWidget {
  const _PremiumLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Tarif wird geladen ...'),
          ],
        ),
      ),
    );
  }
}

class _PremiumErrorCard extends StatelessWidget {
  const _PremiumErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            const Expanded(child: Text('Tarif konnte nicht geladen werden.')),
            TextButton(onPressed: onRetry, child: const Text('Erneut')),
          ],
        ),
      ),
    );
  }
}

class _PremiumFeatureChip extends StatelessWidget {
  const _PremiumFeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Icon(icon, color: colors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
