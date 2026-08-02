import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/vehicle.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _databaseName = 'motorlog.db';
  static const _databaseVersion = 2;

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
}