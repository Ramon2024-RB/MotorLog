import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/vehicle.dart';
import '../../models/fuel_entry.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _databaseName = 'motorlog.db';
  static const _databaseVersion = 3;

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
  }

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
  Future<List<FuelEntry>> getFuelEntries({
  String? vehicleId,
}) async {
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
}