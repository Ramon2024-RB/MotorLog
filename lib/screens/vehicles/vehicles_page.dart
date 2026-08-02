import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_provider.dart';
import 'add_vehicle_dialog.dart';

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  Future<void> _openAddVehicleDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const AddVehicleDialog(),
    );
  }

  Future<void> _openEditVehicleDialog(
    BuildContext context,
    Vehicle vehicle,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddVehicleDialog(vehicle: vehicle);
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
          title: const Text('Fahrzeug löschen?'),
          content: Text(
            'Möchtest du „${vehicle.name}“ wirklich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);
    }
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
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
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
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
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lege dein erstes Fahrzeug an, um Tankvorgänge, Kosten und Wartungen zu erfassen.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _openAddVehicleDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Fahrzeug hinzufügen'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(vehicleProvider.notifier).reload();
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: vehicles.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      child: Icon(
                        vehicle.model.toLowerCase().contains('transit')
                            ? Icons.airport_shuttle
                            : Icons.directions_car,
                      ),
                    ),
                    title: Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${vehicle.brand} ${vehicle.model}\n'
                        '${vehicle.vehicleType} · ${vehicle.year} · '
                        '${vehicle.fuelType} · '
                        '${vehicle.mileage} km'
                        '${vehicle.licensePlate == null ? '' : '\n${vehicle.licensePlate}'}',
                      ),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditVehicleDialog(
                            context,
                            vehicle,
                          );
                        }

                        if (value == 'delete') {
                          _confirmDelete(
                            context,
                            ref,
                            vehicle,
                          );
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 12),
                                Text('Bearbeiten'),
                              ],
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 12),
                                Text('Löschen'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddVehicleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Fahrzeug'),
      ),
    );
  }
}