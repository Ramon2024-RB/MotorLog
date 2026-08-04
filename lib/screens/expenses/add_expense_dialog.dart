import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/expense.dart';
import '../../models/vehicle.dart';
import '../../services/expense_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddExpenseDialog extends ConsumerStatefulWidget {
  const AddExpenseDialog({super.key, this.expense});

  final Expense? expense;

  @override
  ConsumerState<AddExpenseDialog> createState() {
    return _AddExpenseDialogState();
  }
}

class _AddExpenseDialogState extends ConsumerState<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _mileageController;
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late String _selectedCategory;
  late DateTime _selectedDate;

  bool _isSaving = false;

  bool get _isEditing => widget.expense != null;

  static const List<String> _categories = [
    'Wartung',
    'Reparatur',
    'Reifen',
    'Versicherung',
    'Steuer',
    'TÜV',
    'Parken',
    'Maut',
    'Camping',
    'Zubehör',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;

    _selectedVehicleId = expense?.vehicleId;
    _selectedCategory = expense?.category ?? 'Wartung';
    _selectedDate = expense?.date ?? DateTime.now();

    _titleController = TextEditingController(text: expense?.title ?? '');

    _amountController = TextEditingController(
      text: expense == null
          ? ''
          : expense.amount.toStringAsFixed(2).replaceAll('.', ','),
    );

    _mileageController = TextEditingController(
      text: expense?.mileage?.toString() ?? '',
    );

    _notesController = TextEditingController(text: expense?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _mileageController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ein Fahrzeug auswählen.')),
      );
      return;
    }

    final amount = _parseDecimal(_amountController.text);

    final mileageText = _mileageController.text.trim();

    final mileage = mileageText.isEmpty ? null : int.tryParse(mileageText);

    if (amount == null || amount <= 0) {
      return;
    }

    if (mileageText.isNotEmpty && mileage == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final expense = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      vehicleId: _selectedVehicleId!,
      date: _selectedDate,
      category: _selectedCategory,
      amount: amount,
      title: _titleController.text.trim(),
      mileage: mileage,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (_isEditing) {
      await ref.read(expenseProvider.notifier).updateExpense(expense);
    } else {
      await ref.read(expenseProvider.notifier).addExpense(expense);
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
          title: Text(_isEditing ? 'Ausgabe bearbeiten' : 'Ausgabe hinzufügen'),
          leading: IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _saveExpense,
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
                    subtitle: 'Wähle das Fahrzeug für diese Ausgabe aus.',
                    child: Column(
                      children: [
                        _SelectedExpenseVehicleCard(vehicle: selectedVehicle),
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
                    title: 'Ausgabe',
                    subtitle: 'Kategorie, Bezeichnung und Betrag.',
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
                            hint: 'Zum Beispiel: Ölwechsel',
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
                            controller: _amountController,
                            label: 'Betrag',
                            hint: '89,90',
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

                              final amount = _parseDecimal(value);

                              if (amount == null || amount <= 0) {
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
                    subtitle: 'Datum und optionaler Kilometerstand.',
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
                                return null;
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
                    title: 'Notizen',
                    subtitle: 'Zusätzliche Informationen zur Ausgabe.',
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
                          : 'Ausgabe speichern',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveExpense,
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Wartung':
        return Icons.build_outlined;
      case 'Reparatur':
        return Icons.handyman_outlined;
      case 'Reifen':
        return Icons.tire_repair;
      case 'Versicherung':
        return Icons.shield_outlined;
      case 'Steuer':
        return Icons.account_balance_outlined;
      case 'TÜV':
        return Icons.fact_check_outlined;
      case 'Parken':
        return Icons.local_parking;
      case 'Maut':
        return Icons.route;
      case 'Camping':
        return Icons.cabin_outlined;
      case 'Zubehör':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class _SelectedExpenseVehicleCard extends StatelessWidget {
  const _SelectedExpenseVehicleCard({required this.vehicle});

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
                      _ExpenseVehicleInfoChip(
                        icon: Icons.category_outlined,
                        label: vehicle.vehicleType,
                      ),
                      _ExpenseVehicleInfoChip(
                        icon: Icons.local_gas_station_outlined,
                        label: vehicle.fuelType,
                      ),
                      _ExpenseVehicleInfoChip(
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

class _ExpenseVehicleInfoChip extends StatelessWidget {
  const _ExpenseVehicleInfoChip({required this.icon, required this.label});

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
