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
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late String _selectedCategory;
  late DateTime _selectedDate;

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

    _titleController = TextEditingController(text: entry?.title ?? '');

    _costController = TextEditingController(
      text: entry == null
          ? ''
          : entry.cost.toStringAsFixed(2).replaceAll('.', ','),
    );

    _mileageController = TextEditingController(
      text: entry?.mileage.toString() ?? '',
    );

    _notesController = TextEditingController(text: entry?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _mileageController.dispose();
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

  Future<void> _saveMaintenance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      return;
    }

    final cost = _parseDecimal(_costController.text);

    final mileage = int.tryParse(_mileageController.text.trim());

    if (cost == null || mileage == null) {
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
            if (vehicles.isEmpty) {
              return const Center(child: Text('Lege zuerst ein Fahrzeug an.'));
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
                        MotorLogCard(
                          margin: EdgeInsets.zero,
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedVehicle.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                            icon: Icons.build_outlined,
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
                            validator: (value) {
                              final cost = _parseDecimal(value ?? '');

                              if (cost == null || cost < 0) {
                                return 'Ungültiger Betrag';
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
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Datum',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
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
                            validator: (value) {
                              final mileage = int.tryParse(value?.trim() ?? '');

                              if (mileage == null || mileage < 0) {
                                return 'Ungültiger Kilometerstand';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Notizen',
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
