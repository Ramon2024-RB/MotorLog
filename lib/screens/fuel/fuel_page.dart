import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/fuel_entry.dart';
import '../../models/vehicle.dart';
import '../../services/fuel_entry_provider.dart';
import '../../services/vehicle_provider.dart';
import 'add_fuel_entry_dialog.dart';

class FuelPage extends ConsumerWidget {
  const FuelPage({super.key, this.vehicleId});

  final String? vehicleId;

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return const AddFuelEntryDialog();
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, FuelEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddFuelEntryDialog(entry: entry);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FuelEntry entry,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tankvorgang löschen?'),
          content: const Text(
            'Möchtest du diesen Tankvorgang wirklich löschen?',
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
      await ref.read(fuelEntryProvider.notifier).deleteFuelEntry(entry.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(fuelEntryProvider);
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tankvorgänge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Fahrzeuge konnten nicht geladen werden.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
        data: (vehicles) {
          return entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Tankvorgänge konnten nicht geladen werden.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        ref.read(fuelEntryProvider.notifier).reload();
                      },
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) {
              final visibleEntries = vehicleId == null
                  ? entries
                  : entries
                        .where((entry) => entry.vehicleId == vehicleId)
                        .toList();

              if (vehicles.isEmpty) {
                return _NoVehicleView(onAddVehicle: () {});
              }

              if (visibleEntries.isEmpty) {
                return _EmptyFuelView(
                  onAddFuelEntry: () => _openAddDialog(context),
                );
              }

              final vehicleMap = {
                for (final vehicle in vehicles) vehicle.id: vehicle,
              };

              return RefreshIndicator(
                onRefresh: () {
                  return ref.read(fuelEntryProvider.notifier).reload();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: visibleEntries.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    final entry = visibleEntries[index];
                    final vehicle = vehicleMap[entry.vehicleId];

                    return _FuelEntryCard(
                      entry: entry,
                      vehicle: vehicle,
                      onEdit: () {
                        _openEditDialog(context, entry);
                      },
                      onDelete: () {
                        _confirmDelete(context, ref, entry);
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tanken'),
      ),
    );
  }
}

class _FuelEntryCard extends StatelessWidget {
  const _FuelEntryCard({
    required this.entry,
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final FuelEntry entry;
  final Vehicle? vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: colorScheme.onError, size: 30),
            const SizedBox(height: 4),
            Text(
              'Löschen',
              style: TextStyle(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.local_gas_station,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle?.name ?? 'Unbekanntes Fahrzeug',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _EntryValue(
                            label: 'Liter',
                            value: _formatNumber(entry.liters, 2),
                          ),
                          _EntryValue(
                            label: 'Preis/L',
                            value: '${_formatNumber(entry.pricePerLiter, 3)} €',
                          ),
                          _EntryValue(
                            label: 'Gesamt',
                            value: '${_formatNumber(entry.totalPrice, 2)} €',
                          ),
                          _EntryValue(
                            label: 'Kilometer',
                            value: '${entry.mileage} km',
                          ),
                        ],
                      ),
                      if (entry.station != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 17),
                            const SizedBox(width: 6),
                            Expanded(child: Text(entry.station!)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            entry.isFullTank
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 17,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.isFullTank ? 'Vollgetankt' : 'Teilbetankung',
                          ),
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
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  static String _formatNumber(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }
}

class _EntryValue extends StatelessWidget {
  const _EntryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyFuelView extends StatelessWidget {
  const _EmptyFuelView({required this.onAddFuelEntry});

  final VoidCallback onAddFuelEntry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Tankvorgänge',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Erfasse deinen ersten Tankvorgang.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddFuelEntry,
              icon: const Icon(Icons.add),
              label: const Text('Tankvorgang hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoVehicleView extends StatelessWidget {
  const _NoVehicleView({required this.onAddVehicle});

  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Lege zuerst ein Fahrzeug an, bevor du einen Tankvorgang speicherst.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
