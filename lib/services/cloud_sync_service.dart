import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fuel_entry.dart';
import '../models/vehicle.dart';

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  User? get _currentUser => _supabase.auth.currentUser;

  // ---------------------------------------------------------------------------
  // PREMIUM
  // ---------------------------------------------------------------------------

  Future<bool> _isPremium() async {
    final user = _currentUser;

    if (user == null) {
      return false;
    }

    final profile = await _supabase
        .from('profiles')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return false;
    }

    return profile['is_premium'] == true;
  }

  Future<void> _requirePremium() async {
    final user = _currentUser;

    if (user == null) {
      throw const AuthException('Kein Benutzer angemeldet.');
    }

    final premium = await _isPremium();

    if (!premium) {
      throw StateError(
        'Cloud-Synchronisierung ist nur mit MotorLog Premium verfügbar.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FAHRZEUGE
  // ---------------------------------------------------------------------------

  Future<void> uploadVehicle(Vehicle vehicle) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('vehicles_cloud').upsert({
      'id': vehicle.id,
      'user_id': user.id,
      'name': vehicle.name,
      'brand': vehicle.brand,
      'model': vehicle.model,
      'year': vehicle.year,
      'fuel_type': vehicle.fuelType,
      'mileage': vehicle.mileage,
      'license_plate': vehicle.licensePlate,
      'vehicle_type': vehicle.vehicleType,
      'is_default': vehicle.isDefault,
    });
  }

  Future<void> uploadVehicles(List<Vehicle> vehicles) async {
    await _requirePremium();

    if (vehicles.isEmpty) {
      return;
    }

    final user = _currentUser!;

    final rows = vehicles.map((vehicle) {
      return {
        'id': vehicle.id,
        'user_id': user.id,
        'name': vehicle.name,
        'brand': vehicle.brand,
        'model': vehicle.model,
        'year': vehicle.year,
        'fuel_type': vehicle.fuelType,
        'mileage': vehicle.mileage,
        'license_plate': vehicle.licensePlate,
        'vehicle_type': vehicle.vehicleType,
        'is_default': vehicle.isDefault,
      };
    }).toList();

    await _supabase.from('vehicles_cloud').upsert(rows);
  }

  Future<List<Vehicle>> downloadVehicles() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('vehicles_cloud')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return rows.map<Vehicle>((row) {
      return Vehicle(
        id: row['id'] as String,
        name: row['name'] as String,
        brand: row['brand'] as String,
        model: row['model'] as String,
        year: row['year'] as int,
        fuelType: row['fuel_type'] as String,
        mileage: row['mileage'] as int,
        vehicleType: (row['vehicle_type'] as String?) ?? 'Auto',
        licensePlate: row['license_plate'] as String?,
        isDefault: row['is_default'] == true,
      );
    }).toList();
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('vehicles_cloud')
        .delete()
        .eq('id', vehicleId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // TANKVORGÄNGE
  // ---------------------------------------------------------------------------

  Future<void> uploadFuelEntry(FuelEntry entry) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('fuel_entries_cloud').upsert({
      'id': entry.id,
      'user_id': user.id,
      'vehicle_id': entry.vehicleId,
      'date': entry.date.toIso8601String(),
      'mileage': entry.mileage,
      'liters': entry.liters,
      'price_per_liter': entry.pricePerLiter,
      'total_price': entry.totalPrice,
      'is_full_tank': entry.isFullTank,
      'station': entry.station,
      'notes': entry.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadFuelEntries(List<FuelEntry> entries) async {
    await _requirePremium();

    if (entries.isEmpty) {
      return;
    }

    final user = _currentUser!;

    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final rows = entries.map((entry) {
      return {
        'id': entry.id,
        'user_id': user.id,
        'vehicle_id': entry.vehicleId,
        'date': entry.date.toIso8601String(),
        'mileage': entry.mileage,
        'liters': entry.liters,
        'price_per_liter': entry.pricePerLiter,
        'total_price': entry.totalPrice,
        'is_full_tank': entry.isFullTank,
        'station': entry.station,
        'notes': entry.notes,
        'updated_at': updatedAt,
      };
    }).toList();

    await _supabase.from('fuel_entries_cloud').upsert(rows);
  }

  Future<List<FuelEntry>> downloadFuelEntries() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('fuel_entries_cloud')
        .select()
        .eq('user_id', user.id)
        .order('date');

    return rows.map<FuelEntry>((row) {
      return FuelEntry(
        id: row['id'] as String,
        vehicleId: row['vehicle_id'] as String,
        date: DateTime.parse(row['date'] as String),
        mileage: row['mileage'] as int,
        liters: (row['liters'] as num).toDouble(),
        pricePerLiter: (row['price_per_liter'] as num).toDouble(),
        totalPrice: (row['total_price'] as num).toDouble(),
        isFullTank: row['is_full_tank'] == true,
        station: row['station'] as String?,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  Future<void> deleteFuelEntry(String fuelEntryId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('fuel_entries_cloud')
        .delete()
        .eq('id', fuelEntryId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // TEST / STATUS
  // ---------------------------------------------------------------------------

  Future<int> getCloudVehicleCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('vehicles_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudFuelEntryCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('fuel_entries_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }
}
