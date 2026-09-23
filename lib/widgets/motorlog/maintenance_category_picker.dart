import 'package:flutter/material.dart';

class MaintenanceCategoryPicker extends StatelessWidget {
  const MaintenanceCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  static const List<_MaintenanceCategoryGroup> _groups = [
    _MaintenanceCategoryGroup(
      title: 'Häufig',
      categories: [
        _MaintenanceCategory(
          name: 'Ölwechsel',
          icon: Icons.oil_barrel_outlined,
        ),
        _MaintenanceCategory(
          name: 'Inspektion',
          icon: Icons.fact_check_outlined,
        ),
        _MaintenanceCategory(name: 'Bremsen', icon: Icons.car_repair_outlined),
        _MaintenanceCategory(name: 'TÜV', icon: Icons.verified_outlined),
      ],
    ),
    _MaintenanceCategoryGroup(
      title: 'Motor & Filter',
      categories: [
        _MaintenanceCategory(name: 'Luftfilter', icon: Icons.air_outlined),
        _MaintenanceCategory(
          name: 'Innenraumfilter',
          icon: Icons.airline_seat_recline_normal_outlined,
        ),
        _MaintenanceCategory(
          name: 'Kraftstofffilter',
          icon: Icons.local_gas_station_outlined,
        ),
        _MaintenanceCategory(
          name: 'Zündkerzen',
          icon: Icons.electric_bolt_outlined,
        ),
      ],
    ),
    _MaintenanceCategoryGroup(
      title: 'Flüssigkeiten & Antrieb',
      categories: [
        _MaintenanceCategory(name: 'Kühlmittel', icon: Icons.ac_unit_outlined),
        _MaintenanceCategory(
          name: 'Getriebeöl',
          icon: Icons.settings_suggest_outlined,
        ),
        _MaintenanceCategory(name: 'Zahnriemen', icon: Icons.settings_outlined),
      ],
    ),
    _MaintenanceCategoryGroup(
      title: 'Weitere',
      categories: [
        _MaintenanceCategory(name: 'Sonstiges', icon: Icons.build_outlined),
      ],
    ),
  ];

  static IconData iconForCategory(String category) {
    for (final group in _groups) {
      for (final item in group.categories) {
        if (item.name == category) {
          return item.icon;
        }
      }
    }

    return Icons.build_outlined;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) {
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MaintenanceCategorySheet(selectedCategory: value);
      },
    );

    if (selected != null && selected != value) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    iconForCategory(value),
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
                        'Wartungsart',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
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
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCategorySheet extends StatefulWidget {
  const _MaintenanceCategorySheet({required this.selectedCategory});

  final String selectedCategory;

  @override
  State<_MaintenanceCategorySheet> createState() =>
      _MaintenanceCategorySheetState();
}

class _MaintenanceCategorySheetState extends State<_MaintenanceCategorySheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(_MaintenanceCategory category) {
    if (_query.trim().isEmpty) {
      return true;
    }

    return category.name.toLowerCase().contains(_query.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    final visibleGroups = MaintenanceCategoryPicker._groups
        .map(
          (group) => _MaintenanceCategoryGroup(
            title: group.title,
            categories: group.categories.where(_matches).toList(),
          ),
        )
        .where((group) => group.categories.isNotEmpty)
        .toList();

    return Container(
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.88),
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
                        'Wartungsart auswählen',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welche Wartung wurde durchgeführt?',
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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Wartungsart suchen',
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
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.7),
          ),
          Expanded(
            child: visibleGroups.isEmpty
                ? _EmptySearchResult(query: _query)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      20 + mediaQuery.padding.bottom,
                    ),
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
                                    index < group.categories.length;
                                    index++
                                  ) ...[
                                    _CategoryTile(
                                      category: group.categories[index],
                                      selected:
                                          group.categories[index].name ==
                                          widget.selectedCategory,
                                    ),
                                    if (index < group.categories.length - 1)
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
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected});

  final _MaintenanceCategory category;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop(category.name);
        },
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
                  category.icon,
                  size: 22,
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: colors.onPrimary, size: 18),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.query});

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
              'Keine Wartungsart gefunden',
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

class _MaintenanceCategoryGroup {
  const _MaintenanceCategoryGroup({
    required this.title,
    required this.categories,
  });

  final String title;
  final List<_MaintenanceCategory> categories;
}

class _MaintenanceCategory {
  const _MaintenanceCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
