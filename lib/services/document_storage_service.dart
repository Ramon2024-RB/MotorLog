import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DocumentStorageService {
  const DocumentStorageService();

  static const String _documentsFolderName = 'vehicle_documents';

  Future<Directory> _getDocumentsDirectory() async {
    final applicationDirectory = await getApplicationDocumentsDirectory();

    final documentsDirectory = Directory(
      path.join(applicationDirectory.path, _documentsFolderName),
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(recursive: true);
    }

    return documentsDirectory;
  }

  /// Speichert eine ausgewählte Datei dauerhaft im MotorLog-
  /// Dokumentenordner.
  ///
  /// In der Datenbank wird anschließend nur noch ein relativer Pfad
  /// gespeichert, z. B.:
  ///
  /// vehicle_documents/abc123.jpg
  Future<String> saveFile(String sourcePath) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Die ausgewählte Datei wurde nicht gefunden.');
    }

    final documentsDirectory = await _getDocumentsDirectory();

    final extension = path.extension(sourcePath);

    final fileName = '${const Uuid().v4()}$extension';

    final destinationPath = path.join(documentsDirectory.path, fileName);

    await sourceFile.copy(destinationPath);

    return path.join(_documentsFolderName, fileName);
  }

  /// Wandelt den in der Datenbank gespeicherten Pfad in den aktuell
  /// gültigen absoluten Dateipfad um.
  ///
  /// Neue Dokumente besitzen einen relativen Pfad.
  ///
  /// Alte Dokumente können noch einen absoluten Pfad enthalten.
  /// In diesem Fall versuchen wir zusätzlich, die Datei anhand des
  /// Dateinamens im aktuellen MotorLog-Dokumentenordner zu finden.
  Future<String?> resolveFilePath(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) {
      return null;
    }

    final normalizedStoredPath = storedPath.trim();

    // ------------------------------------------------------------
    // Neuer relativer Pfad
    // ------------------------------------------------------------

    if (!path.isAbsolute(normalizedStoredPath)) {
      final applicationDirectory = await getApplicationDocumentsDirectory();

      return path.join(applicationDirectory.path, normalizedStoredPath);
    }

    // ------------------------------------------------------------
    // Alter absoluter Pfad
    // ------------------------------------------------------------

    final oldFile = File(normalizedStoredPath);

    if (await oldFile.exists()) {
      return oldFile.path;
    }

    // ------------------------------------------------------------
    // Falls sich der iOS-App-Container geändert hat:
    // Datei anhand des Dateinamens im aktuellen Dokumentenordner suchen.
    // ------------------------------------------------------------

    final documentsDirectory = await _getDocumentsDirectory();

    final fileName = path.basename(normalizedStoredPath);

    final migratedPath = path.join(documentsDirectory.path, fileName);

    final migratedFile = File(migratedPath);

    if (await migratedFile.exists()) {
      return migratedFile.path;
    }

    return null;
  }

  /// Prüft, ob eine gespeicherte Dokumentdatei tatsächlich existiert.
  Future<bool> fileExists(String? storedPath) async {
    final resolvedPath = await resolveFilePath(storedPath);

    if (resolvedPath == null) {
      return false;
    }

    return File(resolvedPath).exists();
  }

  /// Löscht eine gespeicherte Dokumentdatei.
  Future<void> deleteFile(String? storedPath) async {
    final resolvedPath = await resolveFilePath(storedPath);

    if (resolvedPath == null) {
      return;
    }

    final file = File(resolvedPath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Liefert nur den Dateinamen eines gespeicherten Dokuments.
  String fileName(String? storedPath) {
    if (storedPath == null || storedPath.trim().isEmpty) {
      return '';
    }

    return path.basename(storedPath);
  }
}
