import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/fuel_entry.dart';
import '../../models/vehicle.dart';
import '../../services/fuel_entry_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddFuelEntryDialog extends ConsumerStatefulWidget {
  const AddFuelEntryDialog({super.key, this.entry, this.initialVehicleId});

  final FuelEntry? entry;
  final String? initialVehicleId;

  @override
  ConsumerState<AddFuelEntryDialog> createState() {
    return _AddFuelEntryDialogState();
  }
}

class _AddFuelEntryDialogState extends ConsumerState<AddFuelEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _mileageController;
  late final TextEditingController _litersController;
  late final TextEditingController _pricePerLiterController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _stationController;
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late DateTime _selectedDate;
  late bool _isFullTank;

  bool _isSaving = false;
  bool _isUpdatingTotalPrice = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();

    final entry = widget.entry;

    _selectedVehicleId = entry?.vehicleId ?? widget.initialVehicleId;
    _selectedDate = entry?.date ?? DateTime.now();
    _isFullTank = entry?.isFullTank ?? true;

    _mileageController = TextEditingController(
      text: entry?.mileage.toString() ?? '',
    );

    _litersController = TextEditingController(
      text: entry == null
          ? ''
          : entry.liters.toStringAsFixed(2).replaceAll('.', ','),
    );

    _pricePerLiterController = TextEditingController(
      text: entry == null
          ? ''
          : entry.pricePerLiter.toStringAsFixed(3).replaceAll('.', ','),
    );

    _totalPriceController = TextEditingController(
      text: entry == null
          ? ''
          : entry.totalPrice.toStringAsFixed(2).replaceAll('.', ','),
    );

    _stationController = TextEditingController(text: entry?.station ?? '');

    _notesController = TextEditingController(text: entry?.notes ?? '');

    _litersController.addListener(_calculateTotalPrice);
    _pricePerLiterController.addListener(_calculateTotalPrice);
  }

  @override
  void dispose() {
    _litersController.removeListener(_calculateTotalPrice);
    _pricePerLiterController.removeListener(_calculateTotalPrice);

    _mileageController.dispose();
    _litersController.dispose();
    _pricePerLiterController.dispose();
    _totalPriceController.dispose();
    _stationController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  void _calculateTotalPrice() {
    if (_isUpdatingTotalPrice) {
      return;
    }

    final liters = _parseDecimal(_litersController.text);
    final pricePerLiter = _parseDecimal(_pricePerLiterController.text);

    if (liters == null || pricePerLiter == null) {
      return;
    }

    final totalPrice = liters * pricePerLiter;

    _isUpdatingTotalPrice = true;

    _totalPriceController.text = totalPrice
        .toStringAsFixed(2)
        .replaceAll('.', ',');

    _isUpdatingTotalPrice = false;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }

    return null;
  }

  String? _validatePositiveDecimal(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }

    final parsed = _parseDecimal(value);

    if (parsed == null || parsed <= 0) {
      return 'Bitte einen gültigen Wert eingeben';
    }

    return null;
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ein Fahrzeug auswählen.')),
      );
      return;
    }

    final mileage = int.tryParse(_mileageController.text.trim());
    final liters = _parseDecimal(_litersController.text);
    final pricePerLiter = _parseDecimal(_pricePerLiterController.text);
    final totalPrice = _parseDecimal(_totalPriceController.text);

    if (mileage == null ||
        liters == null ||
        pricePerLiter == null ||
        totalPrice == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final entry = FuelEntry(
      id: widget.entry?.id ?? const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      date: _selectedDate,
      mileage: mileage,
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalPrice: totalPrice,
      isFullTank: _isFullTank,
      station: _stationController.text.trim().isEmpty
          ? null
          : _stationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(fuelEntryProvider.notifier).updateFuelEntry(entry);
    } else {
      await ref.read(fuelEntryProvider.notifier).addFuelEntry(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
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
          title: Text(
            _isEditing ? 'Tankvorgang bearbeiten' : 'Tankvorgang hinzufügen',
          ),
          leading: IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveEntry,
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
                    subtitle: 'Wähle das Fahrzeug für diesen Tankvorgang aus.',
                    child: Column(
                      children: [
                        _SelectedVehicleCard(vehicle: selectedVehicle),
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
                    title: 'Tankdaten',
                    subtitle: 'Kilometerstand, Menge und Kraftstoffpreise.',
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
                              final requiredError = _validateRequired(value);

                              if (requiredError != null) {
                                return requiredError;
                              }

                              final mileage = int.tryParse(value!.trim());

                              if (mileage == null || mileage < 0) {
                                return 'Bitte einen gültigen Kilometerstand eingeben';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _litersController,
                            label: 'Getankte Menge',
                            hint: '55,40',
                            suffixText: 'Liter',
                            icon: Icons.local_gas_station_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validatePositiveDecimal,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _pricePerLiterController,
                            label: 'Preis pro Liter',
                            hint: '1,679',
                            suffixText: '€',
                            icon: Icons.euro,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _validatePositiveDecimal,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _totalPriceController,
                            label: 'Gesamtpreis',
                            hint: '93,02',
                            suffixText: '€',
                            icon: Icons.payments_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validatePositiveDecimal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Weitere Angaben',
                    subtitle: 'Volltank, Tankstelle und optionale Notizen.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile.adaptive(
                            value: _isFullTank,
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      _isFullTank = value;
                                    });
                                  },
                            title: const Text('Vollgetankt'),
                            subtitle: Text(
                              _isFullTank
                                  ? 'Der Tank wurde vollständig gefüllt.'
                                  : 'Es handelt sich um eine Teilbetankung.',
                            ),
                            secondary: const Icon(Icons.local_gas_station),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _stationController,
                            label: 'Tankstelle',
                            hint: 'Zum Beispiel: Aral',
                            icon: Icons.storefront_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _notesController,
                            label: 'Notizen',
                            hint: 'Optional',
                            icon: Icons.notes,
                            minLines: 3,
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: MotorLogButton(
                      label: _isEditing
                          ? 'Änderungen speichern'
                          : 'Tankvorgang speichern',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveEntry,
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

class _SelectedVehicleCard extends StatelessWidget {
  const _SelectedVehicleCard({required this.vehicle});

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
