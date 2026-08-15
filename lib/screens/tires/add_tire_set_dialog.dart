import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/tire_set.dart';
import '../../models/vehicle.dart';
import '../../services/tire_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddTireSetDialog extends ConsumerStatefulWidget {
  const AddTireSetDialog({super.key, this.tireSet, this.initialVehicleId});

  final TireSet? tireSet;
  final String? initialVehicleId;

  @override
  ConsumerState<AddTireSetDialog> createState() {
    return _AddTireSetDialogState();
  }
}

class _AddTireSetDialogState extends ConsumerState<AddTireSetDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _widthController;
  late final TextEditingController _aspectRatioController;
  late final TextEditingController _rimDiameterController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _productionYearController;
  late final TextEditingController _treadDepthController;
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late String _selectedTireType;

  DateTime? _purchaseDate;

  bool _isMounted = false;
  bool _isSaving = false;

  bool get _isEditing => widget.tireSet != null;

  static const List<String> _tireTypes = [
    'Sommerreifen',
    'Winterreifen',
    'Ganzjahresreifen',
  ];

  @override
  void initState() {
    super.initState();

    final tireSet = widget.tireSet;

    _selectedVehicleId = tireSet?.vehicleId ?? widget.initialVehicleId;

    _selectedTireType = tireSet?.tireType ?? 'Sommerreifen';

    _purchaseDate = tireSet?.purchaseDate;
    _isMounted = tireSet?.isMounted ?? false;

    _nameController = TextEditingController(text: tireSet?.name ?? '');

    _widthController = TextEditingController(
      text: tireSet?.width.toString() ?? '',
    );

    _aspectRatioController = TextEditingController(
      text: tireSet?.aspectRatio.toString() ?? '',
    );

    _rimDiameterController = TextEditingController(
      text: tireSet?.rimDiameter.toString() ?? '',
    );

    _manufacturerController = TextEditingController(
      text: tireSet?.manufacturer ?? '',
    );

    _modelController = TextEditingController(text: tireSet?.model ?? '');

    _purchasePriceController = TextEditingController(
      text: tireSet?.purchasePrice == null
          ? ''
          : tireSet!.purchasePrice!.toStringAsFixed(2).replaceAll('.', ','),
    );

    _productionYearController = TextEditingController(
      text: tireSet?.productionYear?.toString() ?? '',
    );

    _treadDepthController = TextEditingController(
      text: tireSet?.treadDepth == null
          ? ''
          : tireSet!.treadDepth!.toStringAsFixed(1).replaceAll('.', ','),
    );

    _notesController = TextEditingController(text: tireSet?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _aspectRatioController.dispose();
    _rimDiameterController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    _purchasePriceController.dispose();
    _productionYearController.dispose();
    _treadDepthController.dispose();
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

  Future<void> _selectPurchaseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? today,
      firstDate: DateTime(1980),
      lastDate: today,
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _purchaseDate = selectedDate;
      });
    }
  }

  Future<void> _saveTireSet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ein Fahrzeug auswählen.')),
      );
      return;
    }

    final width = int.tryParse(_widthController.text.trim());

    final aspectRatio = int.tryParse(_aspectRatioController.text.trim());

    final rimDiameter = int.tryParse(_rimDiameterController.text.trim());

    final purchasePriceText = _purchasePriceController.text.trim();

    final purchasePrice = purchasePriceText.isEmpty
        ? null
        : _parseDecimal(purchasePriceText);

    final productionYearText = _productionYearController.text.trim();

    final productionYear = productionYearText.isEmpty
        ? null
        : int.tryParse(productionYearText);

    final treadDepthText = _treadDepthController.text.trim();

    final treadDepth = treadDepthText.isEmpty
        ? null
        : _parseDecimal(treadDepthText);

    if (width == null || aspectRatio == null || rimDiameter == null) {
      return;
    }

    if (purchasePriceText.isNotEmpty && purchasePrice == null) {
      return;
    }

    if (productionYearText.isNotEmpty && productionYear == null) {
      return;
    }

    if (treadDepthText.isNotEmpty && treadDepth == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final tireSet = TireSet(
      id: widget.tireSet?.id ?? const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      name: _nameController.text.trim(),
      tireType: _selectedTireType,
      width: width,
      aspectRatio: aspectRatio,
      rimDiameter: rimDiameter,
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      purchaseDate: _purchaseDate,
      purchasePrice: purchasePrice,
      productionYear: productionYear,
      treadDepth: treadDepth,
      isMounted: _isMounted,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(tireProvider.notifier).updateTireSet(tireSet);
    } else {
      await ref.read(tireProvider.notifier).addTireSet(tireSet);
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

  IconData _tireTypeIcon(String type) {
    switch (type) {
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
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Reifensatz bearbeiten' : 'Reifensatz hinzufügen',
          ),
          leading: IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveTireSet,
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
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fahrzeuge konnten nicht geladen werden.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
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
                    subtitle: 'Wähle das Fahrzeug für diesen Reifensatz aus.',
                    child: Column(
                      children: [
                        _SelectedTireVehicleCard(vehicle: selectedVehicle),
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
                    title: 'Reifensatz',
                    subtitle: 'Name und Art des Reifensatzes.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          MotorLogTextField(
                            controller: _nameController,
                            label: 'Bezeichnung',
                            hint: 'Zum Beispiel: Winterreifen 2026',
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
                          MotorLogDropdown<String>(
                            value: _selectedTireType,
                            label: 'Reifenart',
                            icon: _tireTypeIcon(_selectedTireType),
                            items: _tireTypes.map((type) {
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
                                        _selectedTireType = value;
                                      });
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),

                  MotorLogSection(
                    title: 'Reifengröße',
                    subtitle: 'Zum Beispiel 215/65 R16.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          MotorLogTextField(
                            controller: _widthController,
                            label: 'Reifenbreite',
                            hint: '215',
                            suffixText: 'mm',
                            icon: Icons.straighten_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              final width = int.tryParse(value.trim());

                              if (width == null || width <= 0) {
                                return 'Bitte eine gültige Reifenbreite eingeben';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _aspectRatioController,
                            label: 'Querschnitt',
                            hint: '65',
                            suffixText: '%',
                            icon: Icons.aspect_ratio_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              final aspectRatio = int.tryParse(value.trim());

                              if (aspectRatio == null || aspectRatio <= 0) {
                                return 'Bitte einen gültigen Querschnitt eingeben';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _rimDiameterController,
                            label: 'Felgendurchmesser',
                            hint: '16',
                            suffixText: 'Zoll',
                            icon: Icons.tire_repair,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              final diameter = int.tryParse(value.trim());

                              if (diameter == null || diameter <= 0) {
                                return 'Bitte einen gültigen Felgendurchmesser eingeben';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  MotorLogSection(
                    title: 'Reifen',
                    subtitle: 'Hersteller und Modell sind optional.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          MotorLogTextField(
                            controller: _manufacturerController,
                            label: 'Hersteller',
                            hint: 'Zum Beispiel: Continental',
                            icon: Icons.factory_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _modelController,
                            label: 'Modell',
                            hint: 'Zum Beispiel: WinterContact TS 870',
                            icon: Icons.label_outline,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _productionYearController,
                            label: 'Produktionsjahr',
                            hint: '2026',
                            icon: Icons.calendar_month_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final year = int.tryParse(value.trim());

                              final currentYear = DateTime.now().year;

                              if (year == null ||
                                  year < 1980 ||
                                  year > currentYear + 1) {
                                return 'Bitte ein gültiges Produktionsjahr eingeben';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _treadDepthController,
                            label: 'Profiltiefe',
                            hint: '8,0',
                            suffixText: 'mm',
                            icon: Icons.height_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final depth = _parseDecimal(value);

                              if (depth == null || depth < 0 || depth > 30) {
                                return 'Bitte eine gültige Profiltiefe eingeben';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  MotorLogSection(
                    title: 'Kauf',
                    subtitle: 'Kaufdatum und Preis sind optional.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _isSaving ? null : _selectPurchaseDate,
                            borderRadius: BorderRadius.circular(18),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Kaufdatum',
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
                                suffixIcon: _purchaseDate == null
                                    ? null
                                    : IconButton(
                                        tooltip: 'Datum entfernen',
                                        onPressed: _isSaving
                                            ? null
                                            : () {
                                                setState(() {
                                                  _purchaseDate = null;
                                                });
                                              },
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                              child: Text(
                                _purchaseDate == null
                                    ? 'Kein Datum ausgewählt'
                                    : _formatDate(_purchaseDate!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _purchasePriceController,
                            label: 'Kaufpreis',
                            hint: '650,00',
                            suffixText: '€',
                            icon: Icons.euro,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }

                              final price = _parseDecimal(value);

                              if (price == null || price < 0) {
                                return 'Bitte einen gültigen Kaufpreis eingeben';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  MotorLogSection(
                    title: 'Status',
                    subtitle: 'Ist dieser Reifensatz aktuell montiert?',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Aktuell montiert',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _isMounted
                              ? 'Dieser Reifensatz ist aktuell am Fahrzeug montiert.'
                              : 'Dieser Reifensatz ist aktuell eingelagert.',
                        ),
                        secondary: Icon(
                          _isMounted
                              ? Icons.check_circle_outline
                              : Icons.inventory_2_outlined,
                        ),
                        value: _isMounted,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isMounted = value;
                                });
                              },
                      ),
                    ),
                  ),

                  MotorLogSection(
                    title: 'Notizen',
                    subtitle: 'Zusätzliche Informationen zum Reifensatz.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: MotorLogTextField(
                        controller: _notesController,
                        label: 'Notizen',
                        hint:
                            'Zum Beispiel Lagerort, Zustand oder Besonderheiten',
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
                          : 'Reifensatz speichern',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveTireSet,
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

class _SelectedTireVehicleCard extends StatelessWidget {
  const _SelectedTireVehicleCard({required this.vehicle});

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
