import 'package:flutter/material.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    required this.onFuelTap,
    required this.onExpenseTap,
    required this.onMaintenanceTap,
    required this.onNewEntryTap,
  });

  final VoidCallback onFuelTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onMaintenanceTap;
  final VoidCallback onNewEntryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _QuickActionCard(
          icon: Icons.local_gas_station_outlined,
          title: 'Tanken',
          subtitle: 'Tankvorgang erfassen',
          onTap: onFuelTap,
        ),
        _QuickActionCard(
          icon: Icons.receipt_long_outlined,
          title: 'Ausgabe',
          subtitle: 'Kosten hinzufügen',
          onTap: onExpenseTap,
        ),
        _QuickActionCard(
          icon: Icons.build_outlined,
          title: 'Wartung',
          subtitle: 'Wartung erfassen',
          onTap: onMaintenanceTap,
        ),
        _QuickActionCard(
          icon: Icons.add_circle_outline,
          title: 'Neu',
          subtitle: 'Eintrag auswählen',
          onTap: onNewEntryTap,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
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