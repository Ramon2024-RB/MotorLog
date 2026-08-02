import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../models/fuel_entry.dart';
import '../../../models/vehicle.dart';
import '../../../services/fuel_entry_provider.dart';
import '../../../services/vehicle_provider.dart';

class AddFuelEntryDialog extends ConsumerStatefulWidget {
  const AddFuelEntryDialog({
    super.key,
    this.entry,
  });

  final FuelEntry? entry;

  @override
  ConsumerState<AddFuelEntryDialog> createState() =>
      _AddFuelEntryDialogState();
}

class _AddFuelEntryDialogState
    extends ConsumerState<AddFuelEntryDialog> {
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

    _selectedVehicleId = entry?.vehicleId;
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

    _stationController = TextEditingController(
      text: entry?.station ?? '',
    );

    _notesController = TextEditingController(
      text: entry?.notes ?? '',
    );

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
    final pricePerLiter =
        _parseDecimal(_pricePerLiterController.text);

    if (liters == null || pricePerLiter == null) {
      return;
    }

    final totalPrice = liters * pricePerLiter;

    _isUpdatingTotalPrice = true;
    _totalPriceController.text =
        totalPrice.toStringAsFixed(2).replaceAll('.', ',');
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
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selectedDate != null) {
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
        const SnackBar(
          content: Text('Bitte ein Fahrzeug auswählen.'),
        ),
      );
      return;
    }

    final mileage =
        int.tryParse(_mileageController.text.trim());
    final liters = _parseDecimal(_litersController.text);
    final pricePerLiter =
        _parseDecimal(_pricePerLiterController.text);
    final totalPrice =
        _parseDecimal(_totalPriceController.text);

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
      await ref
          .read(fuelEntryProvider.notifier)
          .updateFuelEntry(entry);
    } else {
      await ref
          .read(fuelEntryProvider.notifier)
          .addFuelEntry(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? 'Tankvorgang bearbeiten'
                : 'Tankvorgang hinzufügen',
          ),
          leading: IconButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveEntry,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Speichern'),
            ),
          ],
        ),
        body: vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
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

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Fahrzeug',
                      prefixIcon:
                          Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: vehicles.map((vehicle) {
                      return DropdownMenuItem(
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _isSaving ? null : _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Datum',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _formatDate(_selectedDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final requiredError =
                          _validateRequired(value);

                      if (requiredError != null) {
                        return requiredError;
                      }

                      final mileage =
                          int.tryParse(value!.trim());

                      if (mileage == null || mileage < 0) {
                        return 'Bitte einen gültigen Kilometerstand eingeben';
                      }

                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kilometerstand',
                      hintText: '95000',
                      suffixText: 'km',
                      prefixIcon: Icon(Icons.speed),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _litersController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validatePositiveDecimal,
                    decoration: const InputDecoration(
                      labelText: 'Getankte Menge',
                      hintText: '55,40',
                      suffixText: 'Liter',
                      prefixIcon:
                          Icon(Icons.local_gas_station_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pricePerLiterController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _validatePositiveDecimal,
                    decoration: const InputDecoration(
                      labelText: 'Preis pro Liter',
                      hintText: '1,679',
                      suffixText: '€',
                      prefixIcon: Icon(Icons.euro),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validatePositiveDecimal,
                    decoration: const InputDecoration(
                      labelText: 'Gesamtpreis',
                      hintText: '93,02',
                      suffixText: '€',
                      prefixIcon:
                          Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    secondary: const Icon(
                      Icons.local_gas_station,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stationController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Tankstelle',
                      hintText: 'Zum Beispiel: Aral',
                      prefixIcon:
                          Icon(Icons.storefront_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notizen',
                      hintText: 'Optional',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        _isSaving ? null : _saveEntry,
                    icon: const Icon(Icons.save_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      child: Text(
                        _isEditing
                            ? 'Änderungen speichern'
                            : 'Tankvorgang speichern',
                      ),
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

  void _setInitialVehicle(List<Vehicle> vehicles) {
    if (_selectedVehicleId != null) {
      return;
    }

    final defaultVehicles =
        vehicles.where((vehicle) => vehicle.isDefault);

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
}