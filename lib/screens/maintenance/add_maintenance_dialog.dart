import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/maintenance_entry.dart';
import '../../models/vehicle.dart';
import '../../services/maintenance_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddMaintenanceDialog extends ConsumerStatefulWidget {
  const AddMaintenanceDialog({super.key, this.entry, this.initialVehicleId});

  final MaintenanceEntry? entry;
  final String? initialVehicleId;

  @override
  ConsumerState<AddMaintenanceDialog> createState() {
    return _AddMaintenanceDialogState();
  }
}

class _AddMaintenanceDialogState extends ConsumerState<AddMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;
  late final TextEditingController _nextMileageController;
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late String _selectedCategory;
  late DateTime _selectedDate;
  DateTime? _nextDate;

  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  static const List<String> _categories = [
    'Ölwechsel',
    'Inspektion',
    'Bremsen',
    'TÜV',
    'Zahnriemen',
    'Luftfilter',
    'Innenraumfilter',
    'Kraftstofffilter',
    'Zündkerzen',
    'Kühlmittel',
    'Getriebeöl',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    _selectedVehicleId = entry?.vehicleId ?? widget.initialVehicleId;
    _selectedCategory = entry?.category ?? 'Ölwechsel';
    _selectedDate = entry?.date ?? DateTime.now();
    _nextDate = entry?.nextDate;

    _titleController = TextEditingController(text: entry?.title ?? '');

    _costController = TextEditingController(
      text: entry == null
          ? ''
          : entry.cost.toStringAsFixed(2).replaceAll('.', ','),
    );

    _mileageController = TextEditingController(
      text: entry?.mileage.toString() ?? '',
    );

    _nextMileageController = TextEditingController(
      text: entry?.nextMileage?.toString() ?? '',
    );

    _notesController = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _nextMileageController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _setInitialVehicle(List<Vehicle> vehicles) {
    if (_selectedVehicleId != null) {
      return;
    }

    final defaultVehicles = vehicles.where((vehicle) => vehicle.isDefault);

    if (defaultVehicles.isNotEmpty) {
      _selectedVehicleId = defaultVehicles.first.id;
    } else {
      _selectedVehicleId = vehicles.first.id;
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _selectNextDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          _nextDate ?? DateTime(today.year + 1, today.month, today.day),
      firstDate: today,
      lastDate: DateTime(today.year + 20, 12, 31),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _nextDate = selectedDate;
      });
    }
  }

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ein Fahrzeug auswählen.')),
      );
      return;
    }

    final cost = _parseDecimal(_costController.text);
    final mileage = int.tryParse(_mileageController.text.trim());

    final nextMileageText = _nextMileageController.text.trim();

    final nextMileage = nextMileageText.isEmpty
        ? null
        : int.tryParse(nextMileageText);

    if (cost == null || mileage == null) {
      return;
    }

    if (nextMileageText.isNotEmpty && nextMileage == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final entry = MaintenanceEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      date: _selectedDate,
      category: _selectedCategory,
      title: _titleController.text.trim(),
      cost: cost,
      mileage: mileage,
      nextMileage: nextMileage,
      nextDate: _nextDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(maintenanceProvider.notifier).updateMaintenance(entry);
    } else {
      await ref.read(maintenanceProvider.notifier).addMaintenance(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Ölwechsel':
        return Icons.oil_barrel_outlined;
      case 'Inspektion':
        return Icons.fact_check_outlined;
      case 'Bremsen':
        return Icons.car_repair;
      case 'TÜV':
        return Icons.verified_outlined;
      case 'Zahnriemen':
        return Icons.settings_outlined;
      case 'Luftfilter':
        return Icons.air_outlined;
      case 'Innenraumfilter':
        return Icons.airline_seat_recline_normal;
      case 'Kraftstofffilter':
        return Icons.local_gas_station_outlined;
      case 'Zündkerzen':
        return Icons.electric_bolt_outlined;
      case 'Kühlmittel':
        return Icons.ac_unit_outlined;
      case 'Getriebeöl':
        return Icons.settings_suggest_outlined;
      default:
        return Icons.build_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Wartung bearbeiten' : 'Wartung hinzufügen'),
          leading: IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveMaintenance,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
        body: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Fahrzeuge konnten nicht geladen werden.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Lege zuerst ein Fahrzeug an.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            _setInitialVehicle(vehicles);

            final selectedVehicle = vehicles.firstWhere(
              (vehicle) => vehicle.id == _selectedVehicleId,
            );

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                children: [
                  MotorLogSection(
                    title: 'Fahrzeug',
                    subtitle: 'Wähle das Fahrzeug für diese Wartung aus.',
                    child: Column(
                      children: [
                        _SelectedMaintenanceVehicleCard(
                          vehicle: selectedVehicle,
                        ),
                        const SizedBox(height: 14),
                        MotorLogDropdown<String>(
                          value: _selectedVehicleId,
                          label: 'Fahrzeug auswählen',
                          icon: Icons.directions_car_outlined,
                          items: vehicles.map((vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle.id,
                              child: Text(vehicle.name),
                            );
                          }).toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedVehicleId = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  MotorLogSection(
                    title: 'Wartung',
                    subtitle: 'Art, Bezeichnung und Kosten.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          MotorLogDropdown<String>(
                            value: _selectedCategory,
                            label: 'Kategorie',
                            icon: _categoryIcon(_selectedCategory),
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _titleController,
                            label: 'Bezeichnung',
                            hint: 'Zum Beispiel: Großer Kundendienst',
                            icon: Icons.edit_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _costController,
                            label: 'Kosten',
                            hint: '120,00',
                            suffixText: '€',
                            icon: Icons.euro,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              final cost = _parseDecimal(value);

                              if (cost == null || cost < 0) {
                                return 'Bitte einen gültigen Betrag eingeben';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Details',
                    subtitle: 'Datum und Kilometerstand.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _isSaving ? null : _selectDate,
                            borderRadius: BorderRadius.circular(18),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Datum',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLowest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                              ),
                              child: Text(_formatDate(_selectedDate)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _mileageController,
                            label: 'Kilometerstand',
                            hint: '95000',
                            suffixText: 'km',
                            icon: Icons.speed,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              final mileage = int.tryParse(value.trim());

                              if (mileage == null || mileage < 0) {
                                return 'Bitte einen gültigen Kilometerstand eingeben';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Erinnerung',
                    subtitle:
                        'Optional nach Kilometerstand oder Datum erinnern.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          MotorLogTextField(
                            controller: _nextMileageController,
                            label: 'Nächste Wartung bei',
                            hint: '110000',
                            suffixText: 'km',
                            icon: Icons.notification_add_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final nextMileage = int.tryParse(value.trim());

                              if (nextMileage == null || nextMileage < 0) {
                                return 'Bitte einen gültigen Kilometerstand eingeben';
                              }

                              final currentMileage = int.tryParse(
                                _mileageController.text.trim(),
                              );

                              if (currentMileage != null &&
                                  nextMileage <= currentMileage) {
                                return 'Muss über dem aktuellen Kilometerstand liegen';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _isSaving ? null : _selectNextDate,
                            borderRadius: BorderRadius.circular(18),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Nächstes Wartungsdatum',
                                prefixIcon: const Icon(
                                  Icons.event_repeat_outlined,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLowest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                                suffixIcon: _nextDate == null
                                    ? null
                                    : IconButton(
                                        tooltip: 'Datum entfernen',
                                        onPressed: _isSaving
                                            ? null
                                            : () {
                                                setState(() {
                                                  _nextDate = null;
                                                });
                                              },
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                              child: Text(
                                _nextDate == null
                                    ? 'Kein Datum ausgewählt'
                                    : _formatDate(_nextDate!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Notizen',
                    subtitle: 'Zusätzliche Informationen zur Wartung.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: MotorLogTextField(
                        controller: _notesController,
                        label: 'Notizen',
                        hint: 'Optional',
                        icon: Icons.notes,
                        minLines: 4,
                        maxLines: 6,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: MotorLogButton(
                      label: _isEditing
                          ? 'Änderungen speichern'
                          : 'Wartung speichern',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveMaintenance,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SelectedMaintenanceVehicleCard extends StatelessWidget {
  const _SelectedMaintenanceVehicleCard({required this.vehicle});

  final Vehicle vehicle;

  IconData _vehicleIcon() {
    switch (vehicle.vehicleType.toLowerCase()) {
      case 'motorrad':
        return Icons.two_wheeler;
      case 'camper':
        return Icons.airport_shuttle;
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary,
              child: Icon(
                _vehicleIcon(),
                color: colorScheme.onPrimary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${vehicle.brand} ${vehicle.model}'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
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
                        icon: Icons.speed,
                        label: '${vehicle.mileage} km',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
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
