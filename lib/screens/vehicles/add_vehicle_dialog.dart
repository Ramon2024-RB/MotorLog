import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_provider.dart';

class AddVehicleDialog extends ConsumerStatefulWidget {
  const AddVehicleDialog({
    super.key,
    this.vehicle,
  });

  final Vehicle? vehicle;

  @override
  ConsumerState<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends ConsumerState<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _licensePlateController;

  late String _fuelType;
  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _nameController = TextEditingController(
      text: vehicle?.name ?? '',
    );
    _brandController = TextEditingController(
      text: vehicle?.brand ?? '',
    );
    _modelController = TextEditingController(
      text: vehicle?.model ?? '',
    );
    _yearController = TextEditingController(
      text: vehicle?.year.toString() ?? '',
    );
    _mileageController = TextEditingController(
      text: vehicle?.mileage.toString() ?? '',
    );
    _licensePlateController = TextEditingController(
      text: vehicle?.licensePlate ?? '',
    );

    _fuelType = vehicle?.fuelType ?? 'Diesel';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }

    return null;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    final mileage = int.tryParse(_mileageController.text.trim());

    if (year == null || mileage == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: year,
      fuelType: _fuelType,
      mileage: mileage,
      licensePlate: _licensePlateController.text.trim().isEmpty
          ? null
          : _licensePlateController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(vehicleProvider.notifier).updateVehicle(vehicle);
    } else {
      await ref.read(vehicleProvider.notifier).addVehicle(vehicle);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Fahrzeug bearbeiten' : 'Fahrzeug hinzufügen',
          ),
          leading: IconButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveVehicle,
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
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Fahrzeugname',
                  hintText: 'Mein Transit',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Marke',
                  hintText: 'Ford',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                validator: _requiredValidator,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Modell',
                  hintText: 'Transit Custom',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pflichtfeld';
                  }

                  final year = int.tryParse(value.trim());

                  if (year == null || year < 1900 || year > 2100) {
                    return 'Bitte ein gültiges Baujahr eingeben';
                  }

                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Baujahr',
                  hintText: '2019',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
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
                decoration: const InputDecoration(
                  labelText: 'Kilometerstand',
                  hintText: '93000',
                  suffixText: 'km',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _fuelType,
                decoration: const InputDecoration(
                  labelText: 'Kraftstoff',
                  prefixIcon: Icon(Icons.local_gas_station_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Benzin',
                    child: Text('Benzin'),
                  ),
                  DropdownMenuItem(
                    value: 'Diesel',
                    child: Text('Diesel'),
                  ),
                  DropdownMenuItem(
                    value: 'Elektro',
                    child: Text('Elektro'),
                  ),
                  DropdownMenuItem(
                    value: 'Hybrid',
                    child: Text('Hybrid'),
                  ),
                  DropdownMenuItem(
                    value: 'LPG',
                    child: Text('LPG'),
                  ),
                  DropdownMenuItem(
                    value: 'Sonstiges',
                    child: Text('Sonstiges'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _fuelType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kennzeichen',
                  hintText: 'SW-AB 123',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveVehicle,
                icon: Icon(
                  _isEditing ? Icons.edit_outlined : Icons.save_outlined,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _isEditing
                        ? 'Änderungen speichern'
                        : 'Fahrzeug speichern',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}