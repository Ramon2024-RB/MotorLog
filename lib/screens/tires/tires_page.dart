import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tire_mount_history.dart';
import '../../models/tire_set.dart';
import '../../models/vehicle.dart';
import '../../services/tire_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_tire_set_dialog.dart';

class TiresPage extends ConsumerWidget {
  const TiresPage({super.key, required this.vehicleId});

  final String vehicleId;

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddTireSetDialog(initialVehicleId: vehicleId);
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, TireSet tireSet) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddTireSetDialog(tireSet: tireSet);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TireSet tireSet,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reifensatz löschen?'),
          content: Text('Möchtest du „${tireSet.name}“ wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(tireProvider.notifier).deleteTireSet(tireSet.id);
    }
  }

  Future<void> _setMounted(
    BuildContext context,
    WidgetRef ref,
    TireSet tireSet,
  ) async {
    if (tireSet.isMounted) {
      return;
    }

    final vehicles = ref.read(vehicleProvider).value;

    if (vehicles == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fahrzeugdaten sind noch nicht verfügbar.'),
        ),
      );

      return;
    }

    Vehicle? vehicle;

    for (final item in vehicles) {
      if (item.id == vehicleId) {
        vehicle = item;
        break;
      }
    }

    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fahrzeug wurde nicht gefunden.')),
      );

      return;
    }

    final result = await showDialog<_TireMountResult>(
      context: context,
      builder: (context) {
        return _TireMountDialog(
          tireSet: tireSet,
          currentMileage: vehicle!.mileage,
        );
      },
    );

    if (result == null) {
      return;
    }

    await ref
        .read(tireProvider.notifier)
        .setMountedTireSet(
          vehicleId: vehicleId,
          tireSetId: tireSet.id,
          mileage: result.mileage,
          mountedDate: result.date,
        );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${tireSet.name} wurde bei '
          '${_formatMileage(result.mileage)} km '
          'als montiert gespeichert.',
        ),
      ),
    );
  }

  Future<void> _showHistory(
    BuildContext context,
    WidgetRef ref,
    TireSet tireSet,
  ) async {
    final history = await ref
        .read(tireProvider.notifier)
        .getTireMountHistory(tireSetId: tireSet.id);

    if (!context.mounted) {
      return;
    }

    final vehicles = ref.read(vehicleProvider).value;

    int? currentMileage;

    if (vehicles != null) {
      for (final vehicle in vehicles) {
        if (vehicle.id == tireSet.vehicleId) {
          currentMileage = vehicle.mileage;
          break;
        }
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TireHistorySheet(
          tireSet: tireSet,
          history: history,
          currentMileage: currentMileage,
        );
      },
    );
  }

  List<TireSet> _sortTireSets(List<TireSet> tireSets) {
    final sorted = [...tireSets];

    sorted.sort((a, b) {
      if (a.isMounted && !b.isMounted) {
        return -1;
      }

      if (!a.isMounted && b.isMounted) {
        return 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted;
  }

  static String _formatMileage(int mileage) {
    final value = mileage.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(value[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tireSetsAsync = ref.watch(tireProvider);

    ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reifen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: tireSetsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 16),
                  const Text(
                    'Reifensätze konnten nicht '
                    'geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(tireProvider.notifier).reload();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (allTireSets) {
          final tireSets = _sortTireSets(
            allTireSets
                .where((tireSet) => tireSet.vehicleId == vehicleId)
                .toList(),
          );

          if (tireSets.isEmpty) {
            return _EmptyTiresView(
              onAddTireSet: () {
                _openAddDialog(context);
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(tireProvider.notifier).reload();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _TireOverviewCard(tireSets: tireSets),
                const SizedBox(height: 24),
                Text(
                  'Reifensätze',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...tireSets.map((tireSet) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TireSetCard(
                      tireSet: tireSet,
                      totalDistanceFuture: ref
                          .read(tireProvider.notifier)
                          .getTotalTireDistance(tireSet: tireSet),
                      onEdit: () {
                        _openEditDialog(context, tireSet);
                      },
                      onDelete: () {
                        _confirmDelete(context, ref, tireSet);
                      },
                      onSetMounted: () {
                        _setMounted(context, ref, tireSet);
                      },
                      onShowHistory: () {
                        _showHistory(context, ref, tireSet);
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Reifensatz'),
      ),
    );
  }
}

class _TireMountResult {
  const _TireMountResult({required this.mileage, required this.date});

  final int mileage;
  final DateTime date;
}

class _TireMountDialog extends StatefulWidget {
  const _TireMountDialog({required this.tireSet, required this.currentMileage});

  final TireSet tireSet;
  final int currentMileage;

  @override
  State<_TireMountDialog> createState() {
    return _TireMountDialogState();
  }
}

class _TireMountDialogState extends State<_TireMountDialog> {
  late final TextEditingController _mileageController;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    _mileageController = TextEditingController(
      text: widget.currentMileage.toString(),
    );

    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _mileageController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  void _confirm() {
    final mileage = int.tryParse(
      _mileageController.text.trim().replaceAll('.', '').replaceAll(',', ''),
    );

    if (mileage == null || mileage < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte einen gültigen '
            'Kilometerstand eingeben.',
          ),
        ),
      );

      return;
    }

    if (mileage < widget.currentMileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Der Kilometerstand darf '
            'nicht unter '
            '${TiresPage._formatMileage(widget.currentMileage)} '
            'km liegen.',
          ),
        ),
      );

      return;
    }

    Navigator.of(
      context,
    ).pop(_TireMountResult(mileage: mileage, date: _selectedDate));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reifensatz montieren'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Du möchtest '
              '„${widget.tireSet.name}“ '
              'als aktuell montierten '
              'Reifensatz festlegen.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometerstand',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Montagedatum',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aktueller Fahrzeugstand: '
              '${TiresPage._formatMileage(widget.currentMileage)} '
              'km',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Montieren'),
        ),
      ],
    );
  }
}

class _TireOverviewCard extends StatelessWidget {
  const _TireOverviewCard({required this.tireSets});

  final List<TireSet> tireSets;

  @override
  Widget build(BuildContext context) {
    TireSet? mountedTireSet;

    for (final tireSet in tireSets) {
      if (tireSet.isMounted) {
        mountedTireSet = tireSet;
        break;
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.tire_repair,
                    color: colorScheme.onPrimary,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reifenübersicht',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${tireSets.length} '
                        '${tireSets.length == 1 ? 'Reifensatz' : 'Reifensätze'} '
                        'gespeichert',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (mountedTireSet != null) ...[
              Text(
                'Aktuell montiert',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                mountedTireSet.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${mountedTireSet.tireType} · '
                '${mountedTireSet.tireSize}',
              ),
              if (mountedTireSet.mountedMileage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Montiert bei '
                  '${TiresPage._formatMileage(mountedTireSet.mountedMileage!)} '
                  'km',
                ),
              ],
              if (mountedTireSet.mountedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Montiert am '
                  '${_formatDate(mountedTireSet.mountedDate!)}',
                ),
              ],
            ] else ...[
              const Text(
                'Aktuell ist kein '
                'Reifensatz als montiert '
                'markiert.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }
}

class _TireSetCard extends StatelessWidget {
  const _TireSetCard({
    required this.tireSet,
    required this.totalDistanceFuture,
    required this.onEdit,
    required this.onDelete,
    required this.onSetMounted,
    required this.onShowHistory,
  });

  final TireSet tireSet;
  final Future<int> totalDistanceFuture;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetMounted;
  final VoidCallback onShowHistory;

  IconData _tireTypeIcon() {
    switch (tireSet.tireType) {
      case 'Sommerreifen':
        return Icons.wb_sunny_outlined;

      case 'Winterreifen':
        return Icons.ac_unit_outlined;

      case 'Ganzjahresreifen':
        return Icons.all_inclusive;

      default:
        return Icons.tire_repair;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final treadDepth = tireSet.treadDepth;
    final productionYear = tireSet.productionYear;
    final manufacturer = tireSet.manufacturer;
    final model = tireSet.model;

    final manufacturerAndModel = [
      manufacturer,
      model,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    return Dismissible(
      key: ValueKey(tireSet.id),
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
      child: MotorLogCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(_tireTypeIcon(), color: colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tireSet.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              if (tireSet.isMounted)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Montiert',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tireSet.tireType,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TireInfoChip(
                      icon: Icons.straighten,
                      label: tireSet.tireSize,
                    ),
                    if (treadDepth != null)
                      _TireInfoChip(
                        icon: Icons.height,
                        label:
                            '${_formatDecimal(treadDepth, 1)} '
                            'mm Profil',
                      ),
                    if (productionYear != null)
                      _TireInfoChip(
                        icon: Icons.calendar_month_outlined,
                        label: 'Bj. $productionYear',
                      ),
                    if (tireSet.isMounted && tireSet.mountedMileage != null)
                      _TireInfoChip(
                        icon: Icons.speed,
                        label:
                            'seit ${TiresPage._formatMileage(tireSet.mountedMileage!)} '
                            'km',
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                FutureBuilder<int>(
                  future: totalDistanceFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 19,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Laufleistung wird '
                            'berechnet …',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return Row(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 19,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Laufleistung nicht '
                            'verfügbar',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      );
                    }

                    final totalDistance = snapshot.data ?? 0;

                    return Row(
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 19,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gesamtlaufleistung: '
                            '${TiresPage._formatMileage(totalDistance)} '
                            'km',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (manufacturerAndModel.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.tire_repair, size: 18),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          manufacturerAndModel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShowHistory,
                        icon: const Icon(Icons.history),
                        label: const Text('Historie'),
                      ),
                    ),
                    if (!tireSet.isMounted) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onSetMounted,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Montieren'),
                        ),
                      ),
                    ],
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDecimal(double value, int decimalPlaces) {
    return value.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }
}

class _TireHistorySheet extends StatelessWidget {
  const _TireHistorySheet({
    required this.tireSet,
    required this.history,
    required this.currentMileage,
  });

  final TireSet tireSet;
  final List<TireMountHistory> history;
  final int? currentMileage;

  int _distance(TireMountHistory entry) {
    if (entry.unmountedMileage != null) {
      final distance = entry.unmountedMileage! - entry.mountedMileage;

      return distance < 0 ? 0 : distance;
    }

    if (currentMileage != null) {
      final distance = currentMileage! - entry.mountedMileage;

      return distance < 0 ? 0 : distance;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final sortedHistory = [...history]
      ..sort((a, b) => b.mountedDate.compareTo(a.mountedDate));

    var totalDistance = 0;

    for (final entry in sortedHistory) {
      totalDistance += _distance(entry);
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.history, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tireSet.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Wechselhistorie',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route_outlined, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gesamtlaufleistung',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${TiresPage._formatMileage(totalDistance)} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (sortedHistory.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 52,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Noch keine '
                            'Reifenwechsel '
                            'gespeichert.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sortedHistory.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      final entry = sortedHistory[index];

                      return _HistoryEntryCard(
                        entry: entry,
                        distance: _distance(entry),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry, required this.distance});

  final TireMountHistory entry;
  final int distance;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isActive = entry.isActive;

    final endDate = entry.unmountedDate;
    final endMileage = entry.unmountedMileage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isActive
                      ? 'Seit ${_formatDate(entry.mountedDate)}'
                      : '${_formatDate(entry.mountedDate)} – '
                            '${_formatDate(endDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Aktuell',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _HistoryValueRow(
            icon: Icons.play_circle_outline,
            label: 'Montiert',
            value: '${TiresPage._formatMileage(entry.mountedMileage)} km',
          ),
          if (endMileage != null) ...[
            const SizedBox(height: 8),
            _HistoryValueRow(
              icon: Icons.stop_circle_outlined,
              label: 'Demontiert',
              value: '${TiresPage._formatMileage(endMileage)} km',
            ),
          ],
          const SizedBox(height: 8),
          _HistoryValueRow(
            icon: Icons.route_outlined,
            label: isActive ? 'Bisher gefahren' : 'Gefahren',
            value: '${TiresPage._formatMileage(distance)} km',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _HistoryValueRow extends StatelessWidget {
  const _HistoryValueRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: emphasize ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TireInfoChip extends StatelessWidget {
  const _TireInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyTiresView extends StatelessWidget {
  const _EmptyTiresView({required this.onAddTireSet});

  final VoidCallback onAddTireSet;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tire_repair,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Reifensätze',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speichere Sommer-, Winter- '
              'oder Ganzjahresreifen für '
              'dieses Fahrzeug.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddTireSet,
              icon: const Icon(Icons.add),
              label: const Text('Reifensatz hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
