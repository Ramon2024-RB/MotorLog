import 'package:flutter/material.dart';

class MaintenanceWorkOption {
  const MaintenanceWorkOption({
    required this.type,
    required this.name,
    required this.icon,
  });

  final String type;
  final String name;
  final IconData icon;
}

class MaintenanceWorkPickerValue {
  const MaintenanceWorkPickerValue({
    required this.selectedTypes,
    required this.customWorkNames,
  });

  final Set<String> selectedTypes;
  final List<String> customWorkNames;

  int get count => selectedTypes.length + customWorkNames.length;
}

class MaintenanceWorkPicker extends StatelessWidget {
  const MaintenanceWorkPicker({
    super.key,
    required this.selectedTypes,
    required this.customWorkNames,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<String> selectedTypes;
  final List<String> customWorkNames;
  final ValueChanged<MaintenanceWorkPickerValue> onChanged;
  final bool enabled;

  static const List<_MaintenanceWorkGroup> _groups = [
    _MaintenanceWorkGroup(
      title: 'Service & Inspektion',
      works: [
        MaintenanceWorkOption(
          type: 'inspection',
          name: 'Inspektion',
          icon: Icons.fact_check_outlined,
        ),
        MaintenanceWorkOption(
          type: 'oil_change',
          name: 'Ölwechsel',
          icon: Icons.oil_barrel_outlined,
        ),
        MaintenanceWorkOption(
          type: 'oil_filter',
          name: 'Ölfilter',
          icon: Icons.filter_alt_outlined,
        ),
        MaintenanceWorkOption(
          type: 'inspection_hu',
          name: 'HU / AU',
          icon: Icons.verified_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Bremsanlage',
      works: [
        MaintenanceWorkOption(
          type: 'brake_pads_front',
          name: 'Bremsbeläge vorne',
          icon: Icons.car_repair_outlined,
        ),
        MaintenanceWorkOption(
          type: 'brake_discs_front',
          name: 'Bremsscheiben vorne',
          icon: Icons.album_outlined,
        ),
        MaintenanceWorkOption(
          type: 'brake_pads_rear',
          name: 'Bremsbeläge hinten',
          icon: Icons.car_repair_outlined,
        ),
        MaintenanceWorkOption(
          type: 'brake_discs_rear',
          name: 'Bremsscheiben hinten',
          icon: Icons.album_outlined,
        ),
        MaintenanceWorkOption(
          type: 'brake_fluid',
          name: 'Bremsflüssigkeit',
          icon: Icons.water_drop_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Filter',
      works: [
        MaintenanceWorkOption(
          type: 'air_filter',
          name: 'Luftfilter',
          icon: Icons.air_outlined,
        ),
        MaintenanceWorkOption(
          type: 'cabin_filter',
          name: 'Innenraumfilter',
          icon: Icons.airline_seat_recline_normal_outlined,
        ),
        MaintenanceWorkOption(
          type: 'fuel_filter',
          name: 'Kraftstofffilter',
          icon: Icons.local_gas_station_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Motor',
      works: [
        MaintenanceWorkOption(
          type: 'spark_plugs',
          name: 'Zündkerzen',
          icon: Icons.electric_bolt_outlined,
        ),
        MaintenanceWorkOption(
          type: 'timing_belt',
          name: 'Zahnriemen',
          icon: Icons.settings_outlined,
        ),
        MaintenanceWorkOption(
          type: 'serpentine_belt',
          name: 'Keil- / Rippenriemen',
          icon: Icons.settings_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Antrieb',
      works: [
        MaintenanceWorkOption(
          type: 'transmission_oil',
          name: 'Getriebeöl',
          icon: Icons.settings_suggest_outlined,
        ),
        MaintenanceWorkOption(
          type: 'differential_oil',
          name: 'Differentialöl',
          icon: Icons.settings_input_component_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Kühlung',
      works: [
        MaintenanceWorkOption(
          type: 'coolant',
          name: 'Kühlmittel',
          icon: Icons.ac_unit_outlined,
        ),
      ],
    ),
    _MaintenanceWorkGroup(
      title: 'Elektrik',
      works: [
        MaintenanceWorkOption(
          type: 'battery',
          name: 'Batterie',
          icon: Icons.battery_charging_full_outlined,
        ),
      ],
    ),
  ];

  static MaintenanceWorkOption? optionForType(String type) {
    for (final group in _groups) {
      for (final work in group.works) {
        if (work.type == type) {
          return work;
        }
      }
    }

    return null;
  }

  static String nameForType(String type) {
    if (type == 'brakes_legacy') {
      return 'Bremsen';
    }

    return optionForType(type)?.name ?? type;
  }

  static IconData iconForType(String type) {
    if (type == 'brakes_legacy') {
      return Icons.car_repair_outlined;
    }

    return optionForType(type)?.icon ?? Icons.build_outlined;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;

    final selected = await showModalBottomSheet<MaintenanceWorkPickerValue>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaintenanceWorkSheet(
        initiallySelected: selectedTypes,
        initialCustomWorkNames: customWorkNames,
      ),
    );

    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final selectedNames = selectedTypes.map(nameForType).toList()..sort();
    final allSelectedNames = [...selectedNames, ...customWorkNames];
    final selectedCount = allSelectedNames.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.build_circle_outlined,
                        color: colors.onPrimaryContainer,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durchgeführte Arbeiten',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selectedTypes.isEmpty
                                ? 'Arbeiten auswählen'
                                : selectedTypes.length == 1
                                ? '1 Arbeit ausgewählt'
                                : '$selectedCount Arbeiten ausgewählt',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
                if (allSelectedNames.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: allSelectedNames.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(
                            alpha: 0.65,
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceWorkSheet extends StatefulWidget {
  const _MaintenanceWorkSheet({
    required this.initiallySelected,
    required this.initialCustomWorkNames,
  });

  final Set<String> initiallySelected;
  final List<String> initialCustomWorkNames;

  @override
  State<_MaintenanceWorkSheet> createState() => _MaintenanceWorkSheetState();
}

class _MaintenanceWorkSheetState extends State<_MaintenanceWorkSheet> {
  final TextEditingController _searchController = TextEditingController();

  late Set<String> _selectedTypes;
  late List<String> _customWorkNames;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedTypes = {...widget.initiallySelected};
    _customWorkNames = [...widget.initialCustomWorkNames];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(MaintenanceWorkOption work) {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return true;
    }

    return work.name.toLowerCase().contains(query);
  }

  void _toggle(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  Future<void> _addCustomWork() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eigene Arbeit hinzufügen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Bezeichnung',
            hintText: 'z. B. Kupplung erneuert',
          ),
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) Navigator.of(dialogContext).pop(name);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) Navigator.of(dialogContext).pop(name);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name.trim().isEmpty) return;
    setState(() => _customWorkNames.add(name.trim()));
  }

  void _removeCustomWork(int index) {
    setState(() => _customWorkNames.removeAt(index));
  }

  int get _selectedCount => _selectedTypes.length + _customWorkNames.length;

  void _clearSelection() {
    setState(() {
      _selectedTypes.clear();
      _customWorkNames.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    final visibleGroups = MaintenanceWorkPicker._groups
        .map(
          (group) => _MaintenanceWorkGroup(
            title: group.title,
            works: group.works.where(_matches).toList(),
          ),
        )
        .where((group) => group.works.isNotEmpty)
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.92),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durchgeführte Arbeiten',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wähle alle Arbeiten dieses Werkstattbesuchs aus.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTypes.isEmpty
                        ? 'Noch nichts ausgewählt'
                        : _selectedTypes.length == 1
                        ? '1 Arbeit ausgewählt'
                        : '$_selectedCount Arbeiten ausgewählt',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_selectedCount > 0)
                  TextButton(
                    onPressed: _clearSelection,
                    child: const Text('Alle entfernen'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Arbeit suchen',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Suche löschen',
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _addCustomWork,
                  icon: const Icon(Icons.add),
                  label: const Text('Eigene Arbeit hinzufügen'),
                ),
                if (_customWorkNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var index = 0;
                        index < _customWorkNames.length;
                        index++
                      )
                        InputChip(
                          avatar: const Icon(Icons.build_outlined, size: 18),
                          label: Text(_customWorkNames[index]),
                          onDeleted: () => _removeCustomWork(index),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
          Expanded(
            child: visibleGroups.isEmpty
                ? _EmptyWorkSearchResult(query: _query)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: visibleGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final group = visibleGroups[groupIndex];

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: groupIndex == visibleGroups.length - 1
                              ? 0
                              : 22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                              child: Text(
                                group.title.toUpperCase(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < group.works.length;
                                    index++
                                  ) ...[
                                    _WorkTile(
                                      work: group.works[index],
                                      selected: _selectedTypes.contains(
                                        group.works[index].type,
                                      ),
                                      onTap: () =>
                                          _toggle(group.works[index].type),
                                    ),
                                    if (index < group.works.length - 1)
                                      Divider(
                                        height: 1,
                                        indent: 68,
                                        color: colors.outlineVariant.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + mediaQuery.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedCount == 0
                    ? null
                    : () {
                        Navigator.of(context).pop(
                          MaintenanceWorkPickerValue(
                            selectedTypes: Set<String>.from(_selectedTypes),
                            customWorkNames: List<String>.from(
                              _customWorkNames,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.check),
                label: Text(
                  _selectedTypes.length == 1
                      ? '1 Arbeit übernehmen'
                      : '${_selectedTypes.length} Arbeiten übernehmen',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkTile extends StatelessWidget {
  const _WorkTile({
    required this.work,
    required this.selected,
    required this.onTap,
  });

  final MaintenanceWorkOption work;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  work.icon,
                  size: 22,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  work.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: selected ? null : Border.all(color: colors.outline),
                ),
                child: selected
                    ? Icon(Icons.check, color: colors.onPrimary, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWorkSearchResult extends StatelessWidget {
  const _EmptyWorkSearchResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_outlined,
                size: 30,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Arbeit gefunden',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Für „$query“ gibt es keinen Treffer.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceWorkGroup {
  const _MaintenanceWorkGroup({required this.title, required this.works});

  final String title;
  final List<MaintenanceWorkOption> works;
}
