import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/expense.dart';
import '../../models/fuel_entry.dart';
import '../../models/maintenance_entry.dart';
import '../../models/tire_set.dart';
import '../../models/vehicle.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'motorlog.db';
  static const int _databaseVersion = 7;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

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
    await _createTireSetsTable(db);
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
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
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
        notes TEXT,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id)
          ON DELETE CASCADE
      )
    ''');
  }

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
  }

  // ---------------------------------------------------------------------------
  // Fahrzeuge
  // ---------------------------------------------------------------------------

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;

    final maps = await db.query(
      'vehicles',
      orderBy: 'name COLLATE NOCASE ASC',
    );

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

    await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setDefaultVehicle(String vehicleId) async {
    final db = await database;

    await db.transaction((transaction) async {
      await transaction.update(
        'vehicles',
        {'is_default': 0},
      );

      await transaction.update(
        'vehicles',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Tankvorgänge
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

    await db.delete(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Kosten
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

    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Wartungen
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

  Future<void> deleteMaintenanceEntry(String id) async {
    final db = await database;

    await db.delete(
      'maintenance_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Reifen
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

    await db.delete(
      'tire_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
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
}