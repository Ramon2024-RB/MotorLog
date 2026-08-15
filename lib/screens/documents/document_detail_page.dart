import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle_document.dart';
import '../../services/document_provider.dart';
import '../../services/document_storage_service.dart';
import '../../widgets/motorlog/motorlog_card.dart';
import 'add_document_dialog.dart';

class DocumentDetailPage extends ConsumerWidget {
  const DocumentDetailPage({
    super.key,
    required this.documentId,
  });

  final String documentId;

  VehicleDocument? _findDocument(List<VehicleDocument> documents) {
    for (final document in documents) {
      if (document.id == documentId) {
        return document;
      }
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  String _fileName(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final parts = normalizedPath.split('/');

    if (parts.isEmpty) {
      return path;
    }

    return parts.last;
  }

  String _fileExtension(String path) {
    final fileName = _fileName(path);

    if (!fileName.contains('.')) {
      return '';
    }

    return fileName.split('.').last.toLowerCase();
  }

  bool _isImage(String path) {
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'heic',
      'webp',
    };

    return imageExtensions.contains(_fileExtension(path));
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

  Future<void> _openEditDialog(
    BuildContext context,
    VehicleDocument document,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AddDocumentDialog(
          document: document,
        );
      },
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VehicleDocument document,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dokument löschen?'),
          content: Text(
            'Möchtest du „${document.title}“ wirklich löschen?',
          ),
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

    if (shouldDelete != true) {
      return false;
    }

    await ref
        .read(documentProvider.notifier)
        .deleteDocument(document.id);

    return true;
  }

  void _showImagePreview(
    BuildContext context,
    String filePath,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Center(
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'Das Bild konnte nicht angezeigt werden.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton.filled(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFileInfo(
    BuildContext context,
    String filePath,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datei',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName(filePath),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Die externe PDF- und Dateiansicht bauen wir im nächsten Schritt ein.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFile(
    BuildContext context,
    String storedPath,
  ) async {
    const storageService = DocumentStorageService();

    final resolvedFilePath = await storageService.resolveFilePath(
      storedPath,
    );

    if (!context.mounted) {
      return;
    }

    if (resolvedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Die hinterlegte Datei wurde auf dem Gerät nicht gefunden.',
          ),
        ),
      );

      return;
    }

    if (_isImage(storedPath)) {
      _showImagePreview(
        context,
        resolvedFilePath,
      );
      return;
    }

    _showFileInfo(
      context,
      resolvedFilePath,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentProvider);

    final loadedDocuments =
        documentsAsync.asData?.value ?? <VehicleDocument>[];

    final selectedDocument = _findDocument(
      loadedDocuments,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dokumentdetails',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Bearbeiten',
            onPressed: selectedDocument == null
                ? null
                : () {
                    _openEditDialog(
                      context,
                      selectedDocument,
                    );
                  },
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
        ],
      ),
      body: documentsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Das Dokument konnte nicht geladen werden.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(
                            documentProvider.notifier,
                          )
                          .reload();
                    },
                    child: const Text(
                      'Erneut versuchen',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        data: (documents) {
          final document = _findDocument(documents);

          if (document == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Das Dokument wurde nicht gefunden.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final hasFile =
              document.filePath != null &&
              document.filePath!.trim().isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              40,
            ),
            children: [
              _DocumentHeaderCard(
                document: document,
                categoryIcon: _categoryIcon(
                  document.category,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Informationen',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              MotorLogCard(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category_outlined,
                      title: 'Kategorie',
                      value: document.category,
                    ),
                    const Divider(height: 28),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Dokumentdatum',
                      value: _formatDate(
                        document.date,
                      ),
                    ),
                    if (document.notes != null &&
                        document.notes!
                            .trim()
                            .isNotEmpty) ...[
                      const Divider(height: 28),
                      _DetailRow(
                        icon: Icons.notes,
                        title: 'Notizen',
                        value: document.notes!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Datei',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (hasFile)
                _DocumentFileCard(
                  fileName: _fileName(
                    document.filePath!,
                  ),
                  isImage: _isImage(
                    document.filePath!,
                  ),
                  onTap: () {
                    _openFile(
                      context,
                      document.filePath!,
                    );
                  },
                )
              else
                const _NoFileCard(),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  _openEditDialog(
                    context,
                    document,
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text(
                  'Dokument bearbeiten',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final deleted =
                      await _confirmDelete(
                        context,
                        ref,
                        document,
                      );

                  if (deleted && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text(
                  'Dokument löschen',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentHeaderCard extends StatelessWidget {
  const _DocumentHeaderCard({
    required this.document,
    required this.categoryIcon,
  });

  final VehicleDocument document;
  final IconData categoryIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primary,
              child: Icon(
                categoryIcon,
                size: 31,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    document.category,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor:
              colorScheme.primaryContainer,
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentFileCard extends StatelessWidget {
  const _DocumentFileCard({
    required this.fileName,
    required this.isImage,
    required this.onTap,
  });

  final String fileName;
  final bool isImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return MotorLogCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor:
                    colorScheme.primaryContainer,
                child: Icon(
                  isImage
                      ? Icons.image_outlined
                      : Icons.description_outlined,
                  color: colorScheme.primary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isImage
                          ? 'Foto anzeigen'
                          : 'Datei öffnen',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFileCard extends StatelessWidget {
  const _NoFileCard();

  @override
  Widget build(BuildContext context) {
    return MotorLogCard(
      margin: EdgeInsets.zero,
      child: const Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Für dieses Dokument ist keine Datei hinterlegt.',
            ),
          ),
        ],
      ),
    );
  }
}