import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';
import '../../services/document_provider.dart';
import '../../services/vehicle_provider.dart';
import '../../widgets/motorlog/motorlog_button.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import '../../widgets/motorlog/motorlog_dropdown.dart';
import '../../widgets/motorlog/motorlog_section.dart';
import '../../widgets/motorlog/motorlog_text_field.dart';

class AddDocumentDialog extends ConsumerStatefulWidget {
  const AddDocumentDialog({super.key, this.document, this.initialVehicleId});

  final VehicleDocument? document;
  final String? initialVehicleId;

  @override
  ConsumerState<AddDocumentDialog> createState() {
    return _AddDocumentDialogState();
  }
}

class _AddDocumentDialogState extends ConsumerState<AddDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  String? _selectedVehicleId;
  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _filePath;

  bool _isSaving = false;
  bool _isSelectingFile = false;

  bool get _isEditing => widget.document != null;

  static const List<String> _categories = [
    'Rechnung',
    'TÜV',
    'Versicherung',
    'Fahrzeugschein',
    'Kaufvertrag',
    'Werkstatt',
    'Garantie',
    'Steuer',
    'Zulassung',
    'Sonstiges',
  ];

  @override
  void initState() {
    super.initState();

    final document = widget.document;

    _selectedVehicleId = document?.vehicleId ?? widget.initialVehicleId;
    _selectedCategory = document?.category ?? 'Rechnung';
    _selectedDate = document?.date ?? DateTime.now();
    _filePath = document?.filePath;

    _titleController = TextEditingController(text: document?.title ?? '');

    _notesController = TextEditingController(text: document?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  void _setInitialVehicle(List<Vehicle> vehicles) {
    if (_selectedVehicleId != null) {
      final vehicleExists = vehicles.any(
        (vehicle) => vehicle.id == _selectedVehicleId,
      );

      if (vehicleExists) {
        return;
      }
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
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _showFileSourcePicker() async {
    if (_isSaving || _isSelectingFile) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                  title: const Text('Foto aufnehmen'),
                  subtitle: const Text('Dokument mit der Kamera fotografieren'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library_outlined),
                  ),
                  title: const Text('Foto auswählen'),
                  subtitle: const Text('Bild aus der Fotomediathek verwenden'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_open_outlined),
                  ),
                  title: const Text('Datei auswählen'),
                  subtitle: const Text('PDF, Bild oder andere Datei auswählen'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isSelectingFile) {
      return;
    }

    setState(() {
      _isSelectingFile = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (!mounted) {
        return;
      }

      if (image != null) {
        setState(() {
          _filePath = image.path;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto konnte nicht ausgewählt werden: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingFile = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    if (_isSelectingFile) {
      return;
    }

    setState(() {
      _isSelectingFile = true;
    });

    try {
      final file = await FilePicker.pickFile();

      if (!mounted) {
        return;
      }

      if (file != null) {
        final path = file.path;

        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Die ausgewählte Datei besitzt keinen lokalen Dateipfad.',
              ),
            ),
          );

          return;
        }

        setState(() {
          _filePath = path;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datei konnte nicht ausgewählt werden: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingFile = false;
        });
      }
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte ein Fahrzeug auswählen.')),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final document = VehicleDocument(
        id: widget.document?.id ?? const Uuid().v4(),
        vehicleId: _selectedVehicleId!,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        filePath: _filePath,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(documentProvider.notifier).updateDocument(document);
      } else {
        await ref.read(documentProvider.notifier).addDocument(document);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dokument konnte nicht gespeichert werden: $error'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Rechnung':
        return Icons.receipt_long_outlined;
      case 'TÜV':
        return Icons.verified_outlined;
      case 'Versicherung':
        return Icons.shield_outlined;
      case 'Fahrzeugschein':
        return Icons.badge_outlined;
      case 'Kaufvertrag':
        return Icons.handshake_outlined;
      case 'Werkstatt':
        return Icons.build_outlined;
      case 'Garantie':
        return Icons.workspace_premium_outlined;
      case 'Steuer':
        return Icons.account_balance_outlined;
      case 'Zulassung':
        return Icons.directions_car_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _fileName(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final parts = normalizedPath.split('/');

    if (parts.isEmpty) {
      return path;
    }

    return parts.last;
  }

  bool _isImageFile(String path) {
    final lowerPath = path.toLowerCase();

    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.heic') ||
        lowerPath.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? 'Dokument bearbeiten' : 'Dokument hinzufügen',
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
              onPressed: _isSaving ? null : _saveDocument,
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
                    subtitle: 'Wähle das Fahrzeug für dieses Dokument aus.',
                    child: Column(
                      children: [
                        _SelectedDocumentVehicleCard(vehicle: selectedVehicle),
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
                                  if (value == null) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedVehicleId = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  MotorLogSection(
                    title: 'Dokument',
                    subtitle: 'Kategorie und Bezeichnung des Dokuments.',
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
                                    if (value == null) {
                                      return;
                                    }

                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 16),
                          MotorLogTextField(
                            controller: _titleController,
                            label: 'Bezeichnung',
                            hint: 'Zum Beispiel: TÜV Bericht 2026',
                            icon: Icons.edit_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Datum',
                    subtitle: 'Wann wurde das Dokument ausgestellt?',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: _isSaving ? null : _selectDate,
                        borderRadius: BorderRadius.circular(18),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Dokumentdatum',
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
                    ),
                  ),
                  MotorLogSection(
                    title: 'Datei',
                    subtitle:
                        'Füge ein Foto, einen Scan oder eine Datei hinzu.',
                    child: MotorLogCard(
                      margin: EdgeInsets.zero,
                      child: _filePath == null
                          ? _EmptyFileView(
                              isLoading: _isSelectingFile,
                              onAddFile: _showFileSourcePicker,
                            )
                          : _SelectedFileView(
                              fileName: _fileName(_filePath!),
                              isImage: _isImageFile(_filePath!),
                              onReplace: _isSaving
                                  ? null
                                  : _showFileSourcePicker,
                              onRemove: _isSaving
                                  ? null
                                  : () {
                                      setState(() {
                                        _filePath = null;
                                      });
                                    },
                            ),
                    ),
                  ),
                  MotorLogSection(
                    title: 'Notizen',
                    subtitle: 'Zusätzliche Informationen zum Dokument.',
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
                          : 'Dokument speichern',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveDocument,
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

class _SelectedDocumentVehicleCard extends StatelessWidget {
  const _SelectedDocumentVehicleCard({required this.vehicle});

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

class _EmptyFileView extends StatelessWidget {
  const _EmptyFileView({required this.onAddFile, required this.isLoading});

  final VoidCallback onAddFile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(Icons.cloud_upload_outlined, size: 46, color: colorScheme.primary),
        const SizedBox(height: 12),
        const Text(
          'Noch keine Datei hinterlegt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Fotografiere ein Dokument, wähle ein Bild oder füge eine Datei hinzu.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onAddFile,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            isLoading ? 'Wird geöffnet...' : 'Datei oder Foto hinzufügen',
          ),
        ),
      ],
    );
  }
}

class _SelectedFileView extends StatelessWidget {
  const _SelectedFileView({
    required this.fileName,
    required this.isImage,
    required this.onReplace,
    required this.onRemove,
  });

  final String fileName;
  final bool isImage;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                isImage ? Icons.image_outlined : Icons.description_outlined,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isImage ? 'Foto hinterlegt' : 'Datei hinterlegt',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Datei entfernen',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReplace,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Datei ersetzen'),
          ),
        ),
      ],
    );
  }
}
