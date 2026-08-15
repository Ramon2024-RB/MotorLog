import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle_document.dart';
import '../../services/document_provider.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_document_dialog.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key, required this.vehicleId});

  final String vehicleId;

  Future<void> _openAddDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddDocumentDialog(initialVehicleId: vehicleId);
      },
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    VehicleDocument document,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddDocumentDialog(document: document);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VehicleDocument document,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dokument löschen?'),
          content: Text('Möchtest du „${document.title}“ wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await ref.read(documentProvider.notifier).deleteDocument(document.id);
    }
  }

  List<VehicleDocument> _sortDocuments(List<VehicleDocument> documents) {
    final sorted = [...documents];

    sorted.sort((a, b) => b.date.compareTo(a.date));

    return sorted;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dokumente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: documentsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 52),
                  const SizedBox(height: 16),
                  const Text(
                    'Dokumente konnten nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(documentProvider.notifier).reload();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (allDocuments) {
          final documents = _sortDocuments(
            allDocuments
                .where((document) => document.vehicleId == vehicleId)
                .toList(),
          );

          if (documents.isEmpty) {
            return _EmptyDocumentsView(
              onAddDocument: () {
                _openAddDialog(context);
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () {
              return ref.read(documentProvider.notifier).reload();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _DocumentOverviewCard(documents: documents),
                const SizedBox(height: 24),
                Text(
                  'Gespeicherte Dokumente',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...documents.map((document) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DocumentCard(
                      document: document,
                      formattedDate: _formatDate(document.date),
                      onTap: () {
                        _openEditDialog(context, document);
                      },
                      onDelete: () {
                        _confirmDelete(context, ref, document);
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Dokument'),
      ),
    );
  }
}

class _DocumentOverviewCard extends StatelessWidget {
  const _DocumentOverviewCard({required this.documents});

  final List<VehicleDocument> documents;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final documentsWithFile = documents
        .where(
          (document) =>
              document.filePath != null && document.filePath!.trim().isNotEmpty,
        )
        .length;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 29,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.folder_copy_outlined,
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
                        'Dokumentenübersicht',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${documents.length} '
                        '${documents.length == 1 ? 'Dokument' : 'Dokumente'} gespeichert',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _OverviewValue(
                    icon: Icons.description_outlined,
                    value: documents.length.toString(),
                    label: 'Dokumente',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OverviewValue(
                    icon: Icons.attach_file_outlined,
                    value: documentsWithFile.toString(),
                    label: 'Mit Datei',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.formattedDate,
    required this.onTap,
    required this.onDelete,
  });

  final VehicleDocument document;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  IconData _categoryIcon() {
    switch (document.category) {
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

  bool get _hasFile {
    return document.filePath != null && document.filePath!.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(document.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();

        return false;
      },
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: colorScheme.onError, size: 30),
            const SizedBox(height: 4),
            Text(
              'Löschen',
              style: TextStyle(
                color: colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: MotorLogCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(_categoryIcon(), color: colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            document.category,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DocumentInfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: formattedDate,
                    ),
                    _DocumentInfoChip(
                      icon: _hasFile
                          ? Icons.attach_file_outlined
                          : Icons.insert_drive_file_outlined,
                      label: _hasFile ? 'Datei hinterlegt' : 'Ohne Datei',
                    ),
                  ],
                ),
                if (document.notes != null &&
                    document.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, size: 18),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          document.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Antippen zum Bearbeiten',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentInfoChip extends StatelessWidget {
  const _DocumentInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyDocumentsView extends StatelessWidget {
  const _EmptyDocumentsView({required this.onAddDocument});

  final VoidCallback onAddDocument;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_copy_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Noch keine Dokumente',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Speichere Rechnungen, TÜV-Berichte, Versicherungsunterlagen und weitere Fahrzeugdokumente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddDocument,
              icon: const Icon(Icons.add),
              label: const Text('Dokument hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
