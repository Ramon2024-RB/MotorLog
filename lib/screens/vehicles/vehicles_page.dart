import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_vehicle_dialog.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  Future<void> _openAddVehicleDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const AddVehicleDialog();
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Fahrzeug löschen?'),
          content: Text(
            'Möchtest du „${vehicle.name}“ wirklich löschen?\n\n'
            'Alle zugehörigen Tankvorgänge, Kosten und späteren '
            'Wartungseinträge können dadurch ebenfalls gelöscht werden. '
            'Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Fahrzeug löschen'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('„${vehicle.name}“ wurde gelöscht.')),
        );
      }
    }
  }

  Future<void> _setDefaultVehicle(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    if (vehicle.isDefault) {
      return;
    }

    await ref.read(vehicleProvider.notifier).setDefaultVehicle(vehicle.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('„${vehicle.name}“ ist jetzt das Standardfahrzeug.'),
        ),
      );
    }
  }

  List<Vehicle> _sortVehicles(List<Vehicle> vehicles) {
    final sortedVehicles = [...vehicles];

    sortedVehicles.sort((first, second) {
      if (first.isDefault && !second.isDefault) {
        return -1;
      }

      if (!first.isDefault && second.isDefault) {
        return 1;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return sortedVehicles;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meine Fahrzeuge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Fahrzeuge konnten nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(vehicleProvider.notifier).reload();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _EmptyVehiclesView(
              onAddVehicle: () {
                _openAddVehicleDialog(context);
              },
            );
          }

          final sortedVehicles = _sortVehicles(vehicles);

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(vehicleProvider.notifier).reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: sortedVehicles.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 14);
              },
              itemBuilder: (context, index) {
                final vehicle = sortedVehicles[index];

                return Dismissible(
                  key: ValueKey(vehicle.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    await _confirmDelete(context, ref, vehicle);

                    // Die Karte wird vom Provider entfernt.
                    // Dismissible selbst soll sie nicht zusätzlich entfernen.
                    return false;
                  },
                  background: Container(
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 30,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Löschen',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: _VehicleCard(
                    vehicle: vehicle,
                    onTap: () {
                      context.go('/vehicles/${vehicle.id}');
                    },
                    onSetDefault: () {
                      _setDefaultVehicle(context, ref, vehicle);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddVehicleDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Fahrzeug'),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onTap,
    required this.onSetDefault,
  });

  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;

  IconData _vehicleIcon() {
    switch (vehicle.vehicleType.toLowerCase()) {
      case 'camper':
        return Icons.airport_shuttle;
      case 'motorrad':
        return Icons.two_wheeler;
      case 'transporter':
        return Icons.local_shipping_outlined;
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  _vehicleIcon(),
                  size: 31,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: vehicle.isDefault ? null : onSetDefault,
                          tooltip: vehicle.isDefault
                              ? 'Standardfahrzeug'
                              : 'Als Standard festlegen',
                          icon: Icon(
                            vehicle.isDefault ? Icons.star : Icons.star_outline,
                            color: vehicle.isDefault
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${vehicle.brand} ${vehicle.model}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _VehicleInfoChip(
                          icon: Icons.category_outlined,
                          label: vehicle.vehicleType,
                        ),
                        _VehicleInfoChip(
                          icon: Icons.local_gas_station_outlined,
                          label: vehicle.fuelType,
                        ),
                        _VehicleInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: vehicle.year.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${vehicle.mileage} km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (vehicle.licensePlate != null &&
                            vehicle.licensePlate!.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              vehicle.licensePlate!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Antippen zum Bearbeiten',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
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

class _VehicleInfoChip extends StatelessWidget {
  const _VehicleInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyVehiclesView extends StatelessWidget {
  const _EmptyVehiclesView({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Fahrzeuge',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lege dein erstes Fahrzeug an, um Tankvorgänge, '
              'Kosten und Wartungen zu erfassen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddVehicle,
              icon: const Icon(Icons.add),
              label: const Text('Fahrzeug hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
