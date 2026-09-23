import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/expense.dart';
import '../../models/fuel_entry.dart';
import '../../models/maintenance_entry.dart';
import '../../models/maintenance_work.dart';
import '../../models/tire_mount_history.dart';
import '../../models/tire_set.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_document.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _legacyDatabaseName = 'motorlog.db';

  // Die bisherige motorlog.db gehört diesem bestehenden Test-/Premiumkonto.
  // Diese UID wird ausschließlich für die einmalige Migration verwendet.
  static const String _legacyOwnerUserId =
      'edd8f72d-40ab-47cd-aaea-e540fb49eeaa';

  static const int _databaseVersion = 13;

  Database? _database;
  String? _activeUserId;

  // ---------------------------------------------------------------------------
  // BENUTZER-DATENBANK
  // ---------------------------------------------------------------------------

  String _databaseNameForUser(String userId) {
    return 'motorlog_$userId.db';
  }

  String? get activeUserId => _activeUserId;

  Future<void> initializeForCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      await close();
      return;
    }

    await switchToUser(user.id);
  }

  Future<void> switchToUser(String userId) async {
    if (_activeUserId == userId && _database != null) {
      return;
    }

    await close();

    await _migrateLegacyDatabaseIfNeeded(userId);

    _activeUserId = userId;
    _database = await _openDatabaseForUser(userId);
  }

  Future<void> clearActiveUser() async {
    await close();
  }

  Future<void> close() async {
    final database = _database;

    _database = null;
    _activeUserId = null;

    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  Future<Database> get database async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      throw StateError(
        'Es ist kein MotorLog-Benutzer angemeldet. '
        'Die lokale Datenbank kann nicht geöffnet werden.',
      );
    }

    if (_database == null || _activeUserId != currentUser.id) {
      await switchToUser(currentUser.id);
    }

    return _database!;
  }

  Future<Database> _openDatabaseForUser(String userId) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseNameForUser(userId));

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // EINMALIGE MIGRATION DER BISHERIGEN motorlog.db
  // ---------------------------------------------------------------------------

  Future<void> _migrateLegacyDatabaseIfNeeded(String userId) async {
    if (userId != _legacyOwnerUserId) {
      return;
    }

    final databasePath = await getDatabasesPath();

    final legacyPath = join(databasePath, _legacyDatabaseName);
    final userDatabasePath = join(databasePath, _databaseNameForUser(userId));

    final legacyDatabase = File(legacyPath);
    final userDatabase = File(userDatabasePath);

    // Keine alte Datenbank vorhanden -> nichts zu migrieren.
    if (!await legacyDatabase.exists()) {
      return;
    }

    // Die benutzerspezifische Datenbank existiert bereits.
    // In diesem Fall darf die Migration nicht erneut ausgeführt werden.
    if (await userDatabase.exists()) {
      return;
    }

    // Die alte Datenbank wird bewusst KOPIERT und nicht verschoben.
    // motorlog.db bleibt dadurch als zusätzliche Sicherheitskopie bestehen.
    await legacyDatabase.copy(userDatabasePath);
  }

  // ---------------------------------------------------------------------------
  // DATENBANK ERSTELLEN
  // ---------------------------------------------------------------------------

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        fuel_type TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        vehicle_type TEXT NOT NULL DEFAULT 'Auto',
        license_plate TEXT,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _createFuelEntriesTable(db);
    await _createExpensesTable(db);
    await _createMaintenanceTable(db);
    await _createMaintenanceWorksTable(db);
    await _createTireSetsTable(db);
    await _createDocumentsTable(db);
    await _createTireMountHistoryTable(db);
  }

  Future<void> _createFuelEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE fuel_entries (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        liters REAL NOT NULL,
        price_per_liter REAL NOT NULL,
        total_price REAL NOT NULL,
        is_full_tank INTEGER NOT NULL DEFAULT 1,
        station TEXT,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        mileage INTEGER,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMaintenanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance_entries (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        cost REAL NOT NULL,
        mileage INTEGER NOT NULL,
        next_mileage INTEGER,
        next_date TEXT,
        notes TEXT,
        mileage_advance_notified INTEGER NOT NULL DEFAULT 0,
        mileage_due_notified INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createMaintenanceWorksTable(Database db) async {
    await db.execute('''
      CREATE TABLE maintenance_works (
        id TEXT PRIMARY KEY,
        maintenance_entry_id TEXT NOT NULL,
        type TEXT NOT NULL,
        next_mileage INTEGER,
        next_date TEXT,
        mileage_advance_notified INTEGER NOT NULL DEFAULT 0,
        mileage_due_notified INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (maintenance_entry_id)
          REFERENCES maintenance_entries (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX index_maintenance_works_entry_id
      ON maintenance_works (maintenance_entry_id)
    ''');
  }

  Future<void> _createTireSetsTable(Database db) async {
    await db.execute('''
      CREATE TABLE tire_sets (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        name TEXT NOT NULL,
        tire_type TEXT NOT NULL,
        width INTEGER NOT NULL,
        aspect_ratio INTEGER NOT NULL,
        rim_diameter INTEGER NOT NULL,
        manufacturer TEXT,
        model TEXT,
        purchase_date TEXT,
        purchase_price REAL,
        production_year INTEGER,
        tread_depth REAL,
        is_mounted INTEGER NOT NULL DEFAULT 0,
        mounted_mileage INTEGER,
        mounted_date TEXT,
        total_mileage INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createDocumentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE vehicle_documents (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        file_path TEXT,
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTireMountHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE tire_mount_history (
        id TEXT PRIMARY KEY,
        vehicle_id TEXT NOT NULL,
        tire_set_id TEXT NOT NULL,
        mounted_date TEXT NOT NULL,
        mounted_mileage INTEGER NOT NULL,
        unmounted_date TEXT,
        unmounted_mileage INTEGER,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE,
        FOREIGN KEY (tire_set_id) REFERENCES tire_sets (id)
          ON DELETE CASCADE
      )
    ''');
  }

  // ---------------------------------------------------------------------------
  // DATENBANK-UPGRADES
  // ---------------------------------------------------------------------------

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE vehicles "
        "ADD COLUMN vehicle_type TEXT NOT NULL DEFAULT 'Auto'",
      );

      await db.execute(
        'ALTER TABLE vehicles '
        'ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 3) {
      await _createFuelEntriesTable(db);
    }

    if (oldVersion < 4) {
      await _createExpensesTable(db);
    }

    if (oldVersion < 5) {
      await _createMaintenanceTable(db);
    }

    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE maintenance_entries '
        'ADD COLUMN next_mileage INTEGER',
      );

      await db.execute(
        'ALTER TABLE maintenance_entries '
        'ADD COLUMN next_date TEXT',
      );
    }

    if (oldVersion < 7) {
      await _createTireSetsTable(db);
    }

    if (oldVersion < 8) {
      await _createDocumentsTable(db);
    }

    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE maintenance_entries '
        'ADD COLUMN mileage_advance_notified '
        'INTEGER NOT NULL DEFAULT 0',
      );

      await db.execute(
        'ALTER TABLE maintenance_entries '
        'ADD COLUMN mileage_due_notified '
        'INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE tire_sets '
        'ADD COLUMN mounted_mileage INTEGER',
      );

      await db.execute(
        'ALTER TABLE tire_sets '
        'ADD COLUMN mounted_date TEXT',
      );
    }

    if (oldVersion < 11) {
      await _createTireMountHistoryTable(db);
    }

    if (oldVersion < 12) {
      await db.execute(
        'ALTER TABLE tire_sets '
        'ADD COLUMN total_mileage INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 13) {
      await _createMaintenanceWorksTable(db);

      final existingEntries = await db.query(
        'maintenance_entries',
        columns: [
          'id',
          'category',
          'next_mileage',
          'next_date',
          'mileage_advance_notified',
          'mileage_due_notified',
        ],
      );

      for (final entry in existingEntries) {
        final maintenanceEntryId = entry['id'] as String;
        final category = entry['category'] as String;

        await db.insert('maintenance_works', {
          'id': '${maintenanceEntryId}_legacy',
          'maintenance_entry_id': maintenanceEntryId,
          'type': _legacyMaintenanceCategoryToType(category),
          'next_mileage': entry['next_mileage'],
          'next_date': entry['next_date'],
          'mileage_advance_notified': entry['mileage_advance_notified'] ?? 0,
          'mileage_due_notified': entry['mileage_due_notified'] ?? 0,
        });
      }
    }
  }

  String _legacyMaintenanceCategoryToType(String category) {
    switch (category) {
      case 'Ölwechsel':
        return 'oil_change';
      case 'Inspektion':
        return 'inspection';
      case 'Bremsen':
        return 'brakes_legacy';
      case 'TÜV':
        return 'inspection_hu';
      case 'Zahnriemen':
        return 'timing_belt';
      case 'Luftfilter':
        return 'air_filter';
      case 'Innenraumfilter':
        return 'cabin_filter';
      case 'Kraftstofffilter':
        return 'fuel_filter';
      case 'Zündkerzen':
        return 'spark_plugs';
      case 'Kühlmittel':
        return 'coolant';
      case 'Getriebeöl':
        return 'transmission_oil';
      case 'Sonstiges':
        return 'other';
      default:
        return 'other';
    }
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUGE
  // ---------------------------------------------------------------------------

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;

    final maps = await db.query('vehicles', orderBy: 'name COLLATE NOCASE ASC');

    return maps.map(Vehicle.fromMap).toList();
  }

  Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await database;

    await db.insert(
      'vehicles',
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;

    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(String id) async {
    final db = await database;

    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefaultVehicle(String vehicleId) async {
    final db = await database;

    await db.transaction((transaction) async {
      await transaction.update('vehicles', {'is_default': 0});

      await transaction.update(
        'vehicles',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // TANKVORGÄNGE
  // ---------------------------------------------------------------------------

  Future<List<FuelEntry>> getFuelEntries({String? vehicleId}) async {
    final db = await database;

    final maps = await db.query(
      'fuel_entries',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'date DESC, mileage DESC',
    );

    return maps.map(FuelEntry.fromMap).toList();
  }

  Future<void> insertFuelEntry(FuelEntry entry) async {
    final db = await database;

    await db.insert(
      'fuel_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFuelEntry(FuelEntry entry) async {
    final db = await database;

    await db.update(
      'fuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteFuelEntry(String id) async {
    final db = await database;

    await db.delete('fuel_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // KOSTEN
  // ---------------------------------------------------------------------------

  Future<List<Expense>> getExpenses({String? vehicleId}) async {
    final db = await database;

    final maps = await db.query(
      'expenses',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'date DESC',
    );

    return maps.map(Expense.fromMap).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;

    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;

    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;

    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // WARTUNGEN
  // ---------------------------------------------------------------------------

  Future<List<MaintenanceEntry>> getMaintenanceEntries({
    String? vehicleId,
  }) async {
    final db = await database;

    final maps = await db.query(
      'maintenance_entries',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'date DESC, mileage DESC',
    );

    return maps.map(MaintenanceEntry.fromMap).toList();
  }

  Future<void> insertMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await database;

    await db.insert(
      'maintenance_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMaintenanceEntry(MaintenanceEntry entry) async {
    final db = await database;

    await db.update(
      'maintenance_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> updateMaintenanceMileageNotificationStatus({
    required String maintenanceId,
    bool? advanceNotified,
    bool? dueNotified,
  }) async {
    final db = await database;

    final values = <String, Object?>{};

    if (advanceNotified != null) {
      values['mileage_advance_notified'] = advanceNotified ? 1 : 0;
    }

    if (dueNotified != null) {
      values['mileage_due_notified'] = dueNotified ? 1 : 0;
    }

    if (values.isEmpty) {
      return;
    }

    await db.update(
      'maintenance_entries',
      values,
      where: 'id = ?',
      whereArgs: [maintenanceId],
    );
  }

  Future<List<MaintenanceWork>> getMaintenanceWorks({
    String? maintenanceEntryId,
  }) async {
    final db = await database;

    final maps = await db.query(
      'maintenance_works',
      where: maintenanceEntryId == null ? null : 'maintenance_entry_id = ?',
      whereArgs: maintenanceEntryId == null ? null : [maintenanceEntryId],
      orderBy: 'rowid ASC',
    );

    return maps.map(MaintenanceWork.fromMap).toList();
  }

  Future<void> insertMaintenanceWork(MaintenanceWork work) async {
    final db = await database;

    await db.insert(
      'maintenance_works',
      work.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMaintenanceWork(MaintenanceWork work) async {
    final db = await database;

    await db.update(
      'maintenance_works',
      work.toMap(),
      where: 'id = ?',
      whereArgs: [work.id],
    );
  }

  Future<void> deleteMaintenanceWork(String id) async {
    final db = await database;

    await db.delete('maintenance_works', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteMaintenanceWorksForEntry(String maintenanceEntryId) async {
    final db = await database;

    await db.delete(
      'maintenance_works',
      where: 'maintenance_entry_id = ?',
      whereArgs: [maintenanceEntryId],
    );
  }

  Future<void> deleteMaintenanceEntry(String id) async {
    final db = await database;

    await db.delete('maintenance_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // REIFEN
  // ---------------------------------------------------------------------------

  Future<List<TireSet>> getTireSets({String? vehicleId}) async {
    final db = await database;

    final maps = await db.query(
      'tire_sets',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'is_mounted DESC, name COLLATE NOCASE ASC',
    );

    return maps.map(TireSet.fromMap).toList();
  }

  Future<void> insertTireSet(TireSet tireSet) async {
    final db = await database;

    await db.insert(
      'tire_sets',
      tireSet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTireSet(TireSet tireSet) async {
    final db = await database;

    await db.update(
      'tire_sets',
      tireSet.toMap(),
      where: 'id = ?',
      whereArgs: [tireSet.id],
    );
  }

  Future<void> deleteTireSet(String id) async {
    final db = await database;

    await db.delete('tire_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setMountedTireSet({
    required String vehicleId,
    required String tireSetId,
  }) async {
    final db = await database;

    await db.transaction((transaction) async {
      await transaction.update(
        'tire_sets',
        {'is_mounted': 0},
        where: 'vehicle_id = ?',
        whereArgs: [vehicleId],
      );

      await transaction.update(
        'tire_sets',
        {'is_mounted': 1},
        where: 'id = ? AND vehicle_id = ?',
        whereArgs: [tireSetId, vehicleId],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // REIFENWECHSEL-HISTORIE
  // ---------------------------------------------------------------------------

  Future<List<TireMountHistory>> getTireMountHistory({
    String? vehicleId,
    String? tireSetId,
  }) async {
    final db = await database;

    String? where;
    List<Object?>? whereArgs;

    if (vehicleId != null && tireSetId != null) {
      where = 'vehicle_id = ? AND tire_set_id = ?';
      whereArgs = [vehicleId, tireSetId];
    } else if (vehicleId != null) {
      where = 'vehicle_id = ?';
      whereArgs = [vehicleId];
    } else if (tireSetId != null) {
      where = 'tire_set_id = ?';
      whereArgs = [tireSetId];
    }

    final maps = await db.query(
      'tire_mount_history',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'mounted_date DESC, mounted_mileage DESC',
    );

    return maps.map(TireMountHistory.fromMap).toList();
  }

  Future<TireMountHistory?> getActiveTireMount({
    required String vehicleId,
  }) async {
    final db = await database;

    final maps = await db.query(
      'tire_mount_history',
      where:
          'vehicle_id = ? '
          'AND unmounted_date IS NULL '
          'AND unmounted_mileage IS NULL',
      whereArgs: [vehicleId],
      orderBy: 'mounted_date DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TireMountHistory.fromMap(maps.first);
  }

  Future<void> insertTireMountHistory(TireMountHistory history) async {
    final db = await database;

    await db.insert(
      'tire_mount_history',
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTireMountHistory(TireMountHistory history) async {
    final db = await database;

    await db.update(
      'tire_mount_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<void> deleteTireMountHistory(String id) async {
    final db = await database;

    await db.delete('tire_mount_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCompletedTireDistance(String tireSetId) async {
    final history = await getTireMountHistory(tireSetId: tireSetId);

    var totalDistance = 0;

    for (final entry in history) {
      totalDistance += entry.completedDistance ?? 0;
    }

    return totalDistance;
  }

  // ---------------------------------------------------------------------------
  // DOKUMENTE
  // ---------------------------------------------------------------------------

  Future<List<VehicleDocument>> getDocuments({String? vehicleId}) async {
    final db = await database;

    final maps = await db.query(
      'vehicle_documents',
      where: vehicleId == null ? null : 'vehicle_id = ?',
      whereArgs: vehicleId == null ? null : [vehicleId],
      orderBy: 'date DESC, title COLLATE NOCASE ASC',
    );

    return maps.map(VehicleDocument.fromMap).toList();
  }

  Future<void> insertDocument(VehicleDocument document) async {
    final db = await database;

    await db.insert(
      'vehicle_documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDocument(VehicleDocument document) async {
    final db = await database;

    await db.update(
      'vehicle_documents',
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;

    await db.delete('vehicle_documents', where: 'id = ?', whereArgs: [id]);
  }
}
