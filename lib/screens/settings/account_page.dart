import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  SupabaseClient get _supabase => Supabase.instance.client;

  User? get _user => _supabase.auth.currentUser;

  String get _email {
    final email = _user?.email?.trim();

    if (email == null || email.isEmpty) {
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

  List<String> get _providers {
    final providers = <String>{};

    for (final identity in _user?.identities ?? const <UserIdentity>[]) {
      providers.add(identity.provider);
    }

    final appProvider = _user?.appMetadata['provider'];

    if (appProvider is String && appProvider.isNotEmpty) {
      providers.add(appProvider);
    }

    return providers.toList();
  }

  bool get _hasEmailLogin {
    return _providers.contains('email');
  }

  String get _loginMethod {
    final providers = _providers;

    final labels = <String>[];

    if (providers.contains('google')) {
      labels.add('Google');
    }

    if (providers.contains('apple')) {
      labels.add('Apple');
    }

    if (providers.contains('email')) {
      labels.add('E-Mail & Passwort');
    }

    if (labels.isEmpty) {
      return 'MotorLog Konto';
    }

    return labels.join(', ');
  }

  Future<void> _changePassword(BuildContext context) async {
    final email = _user?.email?.trim();

    if (email == null || email.isEmpty) {
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'motorlog://reset-password/',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Wir haben dir eine E-Mail zum Ändern deines Passworts gesendet.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Passwort-E-Mail konnte nicht gesendet werden: ${error.message}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwort-E-Mail konnte nicht gesendet werden: $error'),
        ),
      );
    }
  }

  void _showDeleteAccountInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_forever_outlined),
          title: const Text('Konto löschen'),
          content: const Text(
            'Die sichere Kontolöschung bauen wir im nächsten Schritt ein. '
            'Dabei werden das MotorLog-Konto und die dazugehörigen '
            'Cloud-Daten dauerhaft gelöscht.\n\n'
            'Die Funktion wird erst aktiviert, wenn die serverseitige '
            'Löschung vollständig eingerichtet ist.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Verstanden'),
            ),
          ],
        );
      },
    );
  }

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
          'Kontodaten',
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
                  radius: 36,
                  backgroundColor: colors.primary,
                  child: Text(
                    _initial,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'MotorLog Konto',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
            child: Column(
              children: [
                _AccountInfoTile(
                  icon: Icons.mail_outline,
                  title: 'E-Mail-Adresse',
                  value: _email,
                ),
                const Divider(height: 1),
                _AccountInfoTile(
                  icon: Icons.login,
                  title: 'Anmeldung',
                  value: _loginMethod,
                ),
              ],
            ),
          ),
          if (_hasEmailLogin) ...[
            const SizedBox(height: 28),
            const _SectionTitle(title: 'Sicherheit'),
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
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.lock_reset_outlined, color: colors.primary),
                ),
                title: const Text(
                  'Passwort ändern',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Link zum Ändern des Passworts per E-Mail erhalten',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _changePassword(context);
                },
              ),
            ),
          ],
          const SizedBox(height: 28),
          const _SectionTitle(title: 'Konto verwalten'),
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
                child: Icon(
                  Icons.delete_forever_outlined,
                  color: colors.onErrorContainer,
                ),
              ),
              title: Text(
                'Konto löschen',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text(
                'MotorLog-Konto und Cloud-Daten dauerhaft löschen',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showDeleteAccountInfo(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoTile extends StatelessWidget {
  const _AccountInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

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
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
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
