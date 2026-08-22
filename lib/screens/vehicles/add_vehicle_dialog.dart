import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddVehicleDialog extends ConsumerStatefulWidget {
  const AddVehicleDialog({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  ConsumerState<AddVehicleDialog> createState() {
    return _AddVehicleDialogState();
  }
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
  late String _vehicleType;

  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  static const List<String> _vehicleTypes = [
    'Auto',
    'Camper',
    'Motorrad',
    'Transporter',
    'Sonstiges',
  ];

  static const List<String> _fuelTypes = [
    'Benzin',
    'Diesel',
    'Elektro',
    'Hybrid',
    'LPG',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _nameController = TextEditingController(text: vehicle?.name ?? '');
    _brandController = TextEditingController(text: vehicle?.brand ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');

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
    _vehicleType = vehicle?.vehicleType ?? 'Auto';
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

  String? _yearValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }

    final year = int.tryParse(value.trim());
    final maximumYear = DateTime.now().year + 1;

    if (year == null || year < 1900 || year > maximumYear) {
      return 'Bitte ein gültiges Baujahr eingeben';
    }

    return null;
  }

  String? _mileageValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pflichtfeld';
    }

    final mileage = int.tryParse(value.trim());

    if (mileage == null || mileage < 0) {
      return 'Bitte einen gültigen Kilometerstand eingeben';
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
      vehicleType: _vehicleType,
      mileage: mileage,
      licensePlate: _licensePlateController.text.trim().isEmpty
          ? null
          : _licensePlateController.text.trim().toUpperCase(),
      isDefault: widget.vehicle?.isDefault ?? false,
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

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
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

  IconData _fuelIcon(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'elektro':
        return Icons.electric_bolt;
      case 'hybrid':
        return Icons.energy_savings_leaf_outlined;
      default:
        return Icons.local_gas_station_outlined;
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
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveVehicle,
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
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              MotorLogSection(
                title: 'Vorschau',
                subtitle: 'So wird dein Fahrzeug in MotorLog dargestellt.',
                child: _VehiclePreviewCard(
                  name: _nameController.text.trim(),
                  brand: _brandController.text.trim(),
                  model: _modelController.text.trim(),
                  mileage: _mileageController.text.trim(),
                  vehicleType: _vehicleType,
                  fuelType: _fuelType,
                  vehicleIcon: _vehicleIcon(_vehicleType),
                  isDefault: widget.vehicle?.isDefault ?? false,
                ),
              ),

              MotorLogSection(
                title: 'Fahrzeugdaten',
                subtitle: 'Name, Marke und Modell deines Fahrzeugs.',
                child: MotorLogCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      MotorLogTextField(
                        controller: _nameController,
                        label: 'Fahrzeugname',
                        hint: 'Zum Beispiel: Schorschi',
                        icon: Icons.drive_file_rename_outline,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      MotorLogTextField(
                        controller: _brandController,
                        label: 'Marke',
                        hint: 'Ford',
                        icon: Icons.business_outlined,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      MotorLogTextField(
                        controller: _modelController,
                        label: 'Modell',
                        hint: 'Transit Custom',
                        icon: Icons.directions_car_outlined,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),

              MotorLogSection(
                title: 'Technische Daten',
                subtitle:
                    'Fahrzeugart, Kraftstoff und aktueller Kilometerstand.',
                child: MotorLogCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      MotorLogDropdown<String>(
                        value: _vehicleType,
                        label: 'Fahrzeugtyp',
                        icon: _vehicleIcon(_vehicleType),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _vehicleType = value;
                                  });
                                }
                              },
                      ),

                      const SizedBox(height: 16),

                      MotorLogDropdown<String>(
                        value: _fuelType,
                        label: 'Kraftstoff',
                        icon: _fuelIcon(_fuelType),
                        items: _fuelTypes.map((fuelType) {
                          return DropdownMenuItem<String>(
                            value: fuelType,
                            child: Text(fuelType),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _fuelType = value;
                                  });
                                }
                              },
                      ),

                      const SizedBox(height: 16),

                      MotorLogTextField(
                        controller: _yearController,
                        label: 'Baujahr',
                        hint: '2019',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _yearValidator,
                      ),

                      const SizedBox(height: 16),

                      MotorLogTextField(
                        controller: _mileageController,
                        label: 'Kilometerstand',
                        hint: '93000',
                        suffixText: 'km',
                        icon: Icons.speed,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: _mileageValidator,
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),

              MotorLogSection(
                title: 'Kennzeichen',
                subtitle:
                    'Das Kennzeichen ist optional und kann später ergänzt werden.',
                child: MotorLogCard(
                  margin: EdgeInsets.zero,
                  child: TextFormField(
                    controller: _licensePlateController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Kennzeichen',
                      hintText: 'SW-AB 123',
                      prefixIcon: const Icon(Icons.badge_outlined),
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
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: MotorLogButton(
                  label: _isEditing
                      ? 'Änderungen speichern'
                      : 'Fahrzeug speichern',
                  icon: _isEditing ? Icons.edit_outlined : Icons.save_outlined,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveVehicle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehiclePreviewCard extends StatelessWidget {
  const _VehiclePreviewCard({
    required this.name,
    required this.brand,
    required this.model,
    required this.mileage,
    required this.vehicleType,
    required this.fuelType,
    required this.vehicleIcon,
    required this.isDefault,
  });

  final String name;
  final String brand;
  final String model;
  final String mileage;
  final String vehicleType;
  final String fuelType;
  final IconData vehicleIcon;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = name.isEmpty ? 'Mein Fahrzeug' : name;

    final vehicleDescription = [
      if (brand.isNotEmpty) brand,
      if (model.isNotEmpty) model,
    ].join(' ');

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
              radius: 29,
              backgroundColor: colorScheme.primary,
              child: Icon(vehicleIcon, size: 31, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isDefault) const Icon(Icons.star, size: 20),
                    ],
                  ),
                  if (vehicleDescription.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      vehicleDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _PreviewChip(icon: vehicleIcon, label: vehicleType),
                      _PreviewChip(
                        icon: Icons.local_gas_station_outlined,
                        label: fuelType,
                      ),
                      _PreviewChip(
                        icon: Icons.speed,
                        label: mileage.isEmpty ? '0 km' : '$mileage km',
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

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.label});

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
