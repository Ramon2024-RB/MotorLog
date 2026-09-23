import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense.dart';
import '../models/fuel_entry.dart';
import '../models/maintenance_entry.dart';
import '../models/maintenance_work.dart';
import '../models/tire_mount_history.dart';
import '../models/tire_set.dart';
import '../models/vehicle.dart';
import '../models/vehicle_document.dart';
import 'document_storage_service.dart';

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  static const String _documentBucket = 'motorlog-documents';

  final DocumentStorageService _documentStorageService =
      const DocumentStorageService();

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
  // KOSTEN
  // ---------------------------------------------------------------------------

  Future<void> uploadExpense(Expense expense) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('expenses_cloud').upsert({
      'id': expense.id,
      'user_id': user.id,
      'vehicle_id': expense.vehicleId,
      'date': expense.date.toIso8601String(),
      'category': expense.category,
      'amount': expense.amount,
      'title': expense.title,
      'mileage': expense.mileage,
      'notes': expense.notes,
    });
  }

  Future<void> uploadExpenses(List<Expense> expenses) async {
    await _requirePremium();

    if (expenses.isEmpty) {
      return;
    }

    final user = _currentUser!;

    final rows = expenses.map((expense) {
      return {
        'id': expense.id,
        'user_id': user.id,
        'vehicle_id': expense.vehicleId,
        'date': expense.date.toIso8601String(),
        'category': expense.category,
        'amount': expense.amount,
        'title': expense.title,
        'mileage': expense.mileage,
        'notes': expense.notes,
      };
    }).toList();

    await _supabase.from('expenses_cloud').upsert(rows);
  }

  Future<List<Expense>> downloadExpenses() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('expenses_cloud')
        .select()
        .eq('user_id', user.id)
        .order('date');

    return rows.map<Expense>((row) {
      return Expense(
        id: row['id'] as String,
        vehicleId: row['vehicle_id'] as String,
        date: DateTime.parse(row['date'] as String),
        category: row['category'] as String,
        amount: (row['amount'] as num).toDouble(),
        title: row['title'] as String,
        mileage: row['mileage'] as int?,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('expenses_cloud')
        .delete()
        .eq('id', expenseId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // WARTUNGEN
  // ---------------------------------------------------------------------------

  Future<void> uploadMaintenanceEntry(MaintenanceEntry entry) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('maintenance_entries_cloud').upsert({
      'id': entry.id,
      'user_id': user.id,
      'vehicle_id': entry.vehicleId,
      'date': entry.date.toIso8601String(),
      'category': entry.category,
      'title': entry.title,
      'cost': entry.cost,
      'mileage': entry.mileage,
      'notes': entry.notes,
      'next_mileage': entry.nextMileage,
      'next_date': entry.nextDate?.toIso8601String(),
      'mileage_advance_notified': entry.mileageAdvanceNotified,
      'mileage_due_notified': entry.mileageDueNotified,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadMaintenanceEntries(List<MaintenanceEntry> entries) async {
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
        'category': entry.category,
        'title': entry.title,
        'cost': entry.cost,
        'mileage': entry.mileage,
        'notes': entry.notes,
        'next_mileage': entry.nextMileage,
        'next_date': entry.nextDate?.toIso8601String(),
        'mileage_advance_notified': entry.mileageAdvanceNotified,
        'mileage_due_notified': entry.mileageDueNotified,
        'updated_at': updatedAt,
      };
    }).toList();

    await _supabase.from('maintenance_entries_cloud').upsert(rows);
  }

  Future<List<MaintenanceEntry>> downloadMaintenanceEntries() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('maintenance_entries_cloud')
        .select()
        .eq('user_id', user.id)
        .order('date');

    return rows.map<MaintenanceEntry>((row) {
      return MaintenanceEntry(
        id: row['id'] as String,
        vehicleId: row['vehicle_id'] as String,
        date: DateTime.parse(row['date'] as String),
        category: row['category'] as String,
        title: row['title'] as String,
        cost: (row['cost'] as num).toDouble(),
        mileage: row['mileage'] as int,
        notes: row['notes'] as String?,
        nextMileage: row['next_mileage'] as int?,
        nextDate: row['next_date'] == null
            ? null
            : DateTime.parse(row['next_date'] as String),
        mileageAdvanceNotified: row['mileage_advance_notified'] == true,
        mileageDueNotified: row['mileage_due_notified'] == true,
      );
    }).toList();
  }

  Future<void> deleteMaintenanceEntry(String maintenanceEntryId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('maintenance_entries_cloud')
        .delete()
        .eq('id', maintenanceEntryId)
        .eq('user_id', user.id);
  }

  Future<void> uploadMaintenanceWork(MaintenanceWork work) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('maintenance_works_cloud').upsert({
      'id': work.id,
      'user_id': user.id,
      'maintenance_entry_id': work.maintenanceEntryId,
      'type': work.type,
      'custom_name': work.customName,
      'next_mileage': work.nextMileage,
      'next_date': work.nextDate?.toIso8601String(),
      'mileage_advance_notified': work.mileageAdvanceNotified,
      'mileage_due_notified': work.mileageDueNotified,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadMaintenanceWorks(List<MaintenanceWork> works) async {
    await _requirePremium();

    if (works.isEmpty) {
      return;
    }

    final user = _currentUser!;
    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final rows = works.map((work) {
      return {
        'id': work.id,
        'user_id': user.id,
        'maintenance_entry_id': work.maintenanceEntryId,
        'type': work.type,
        'custom_name': work.customName,
        'next_mileage': work.nextMileage,
        'next_date': work.nextDate?.toIso8601String(),
        'mileage_advance_notified': work.mileageAdvanceNotified,
        'mileage_due_notified': work.mileageDueNotified,
        'updated_at': updatedAt,
      };
    }).toList();

    await _supabase.from('maintenance_works_cloud').upsert(rows);
  }

  Future<List<MaintenanceWork>> downloadMaintenanceWorks({
    String? maintenanceEntryId,
  }) async {
    await _requirePremium();

    final user = _currentUser!;

    var query = _supabase
        .from('maintenance_works_cloud')
        .select()
        .eq('user_id', user.id);

    if (maintenanceEntryId != null) {
      query = query.eq('maintenance_entry_id', maintenanceEntryId);
    }

    final rows = await query.order('created_at');

    return rows.map<MaintenanceWork>((row) {
      return MaintenanceWork(
        id: row['id'] as String,
        maintenanceEntryId: row['maintenance_entry_id'] as String,
        type: row['type'] as String,
        customName: row['custom_name'] as String?,
        nextMileage: row['next_mileage'] as int?,
        nextDate: row['next_date'] == null
            ? null
            : DateTime.parse(row['next_date'] as String),
        mileageAdvanceNotified: row['mileage_advance_notified'] == true,
        mileageDueNotified: row['mileage_due_notified'] == true,
      );
    }).toList();
  }

  Future<void> replaceMaintenanceWorks(
    String maintenanceEntryId,
    List<MaintenanceWork> works,
  ) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('maintenance_works_cloud')
        .delete()
        .eq('maintenance_entry_id', maintenanceEntryId)
        .eq('user_id', user.id);

    if (works.isEmpty) {
      return;
    }

    await uploadMaintenanceWorks(works);
  }

  Future<void> deleteMaintenanceWorksForEntry(String maintenanceEntryId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('maintenance_works_cloud')
        .delete()
        .eq('maintenance_entry_id', maintenanceEntryId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // REIFENSÄTZE
  // ---------------------------------------------------------------------------

  Future<void> uploadTireSet(TireSet tireSet) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('tire_sets_cloud').upsert({
      'id': tireSet.id,
      'user_id': user.id,
      'vehicle_id': tireSet.vehicleId,
      'name': tireSet.name,
      'tire_type': tireSet.tireType,
      'width': tireSet.width,
      'aspect_ratio': tireSet.aspectRatio,
      'rim_diameter': tireSet.rimDiameter,
      'manufacturer': tireSet.manufacturer,
      'model': tireSet.model,
      'purchase_date': tireSet.purchaseDate?.toIso8601String(),
      'purchase_price': tireSet.purchasePrice,
      'production_year': tireSet.productionYear,
      'tread_depth': tireSet.treadDepth,
      'is_mounted': tireSet.isMounted,
      'mounted_mileage': tireSet.mountedMileage,
      'mounted_date': tireSet.mountedDate?.toIso8601String(),
      'total_mileage': tireSet.totalMileage,
      'notes': tireSet.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadTireSets(List<TireSet> tireSets) async {
    await _requirePremium();

    if (tireSets.isEmpty) {
      return;
    }

    final user = _currentUser!;
    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final rows = tireSets.map((tireSet) {
      return {
        'id': tireSet.id,
        'user_id': user.id,
        'vehicle_id': tireSet.vehicleId,
        'name': tireSet.name,
        'tire_type': tireSet.tireType,
        'width': tireSet.width,
        'aspect_ratio': tireSet.aspectRatio,
        'rim_diameter': tireSet.rimDiameter,
        'manufacturer': tireSet.manufacturer,
        'model': tireSet.model,
        'purchase_date': tireSet.purchaseDate?.toIso8601String(),
        'purchase_price': tireSet.purchasePrice,
        'production_year': tireSet.productionYear,
        'tread_depth': tireSet.treadDepth,
        'is_mounted': tireSet.isMounted,
        'mounted_mileage': tireSet.mountedMileage,
        'mounted_date': tireSet.mountedDate?.toIso8601String(),
        'total_mileage': tireSet.totalMileage,
        'notes': tireSet.notes,
        'updated_at': updatedAt,
      };
    }).toList();

    await _supabase.from('tire_sets_cloud').upsert(rows);
  }

  Future<List<TireSet>> downloadTireSets() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('tire_sets_cloud')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return rows.map<TireSet>((row) {
      return TireSet(
        id: row['id'] as String,
        vehicleId: row['vehicle_id'] as String,
        name: row['name'] as String,
        tireType: row['tire_type'] as String,
        width: row['width'] as int,
        aspectRatio: row['aspect_ratio'] as int,
        rimDiameter: row['rim_diameter'] as int,
        manufacturer: row['manufacturer'] as String?,
        model: row['model'] as String?,
        purchaseDate: row['purchase_date'] == null
            ? null
            : DateTime.parse(row['purchase_date'] as String),
        purchasePrice: row['purchase_price'] == null
            ? null
            : (row['purchase_price'] as num).toDouble(),
        productionYear: row['production_year'] as int?,
        treadDepth: row['tread_depth'] == null
            ? null
            : (row['tread_depth'] as num).toDouble(),
        isMounted: row['is_mounted'] == true,
        mountedMileage: row['mounted_mileage'] as int?,
        mountedDate: row['mounted_date'] == null
            ? null
            : DateTime.parse(row['mounted_date'] as String),
        totalMileage: row['total_mileage'] as int? ?? 0,
        notes: row['notes'] as String?,
      );
    }).toList();
  }

  Future<void> deleteTireSet(String tireSetId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('tire_sets_cloud')
        .delete()
        .eq('id', tireSetId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // REIFENWECHSEL-HISTORIE
  // ---------------------------------------------------------------------------

  Future<void> uploadTireMountHistory(TireMountHistory history) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase.from('tire_mount_history_cloud').upsert({
      'id': history.id,
      'user_id': user.id,
      'vehicle_id': history.vehicleId,
      'tire_set_id': history.tireSetId,
      'mounted_date': history.mountedDate.toIso8601String(),
      'mounted_mileage': history.mountedMileage,
      'unmounted_date': history.unmountedDate?.toIso8601String(),
      'unmounted_mileage': history.unmountedMileage,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadTireMountHistories(
    List<TireMountHistory> histories,
  ) async {
    await _requirePremium();

    if (histories.isEmpty) {
      return;
    }

    final user = _currentUser!;
    final updatedAt = DateTime.now().toUtc().toIso8601String();

    final rows = histories.map((history) {
      return {
        'id': history.id,
        'user_id': user.id,
        'vehicle_id': history.vehicleId,
        'tire_set_id': history.tireSetId,
        'mounted_date': history.mountedDate.toIso8601String(),
        'mounted_mileage': history.mountedMileage,
        'unmounted_date': history.unmountedDate?.toIso8601String(),
        'unmounted_mileage': history.unmountedMileage,
        'updated_at': updatedAt,
      };
    }).toList();

    await _supabase.from('tire_mount_history_cloud').upsert(rows);
  }

  Future<List<TireMountHistory>> downloadTireMountHistories() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('tire_mount_history_cloud')
        .select()
        .eq('user_id', user.id)
        .order('mounted_date');

    return rows.map<TireMountHistory>((row) {
      return TireMountHistory(
        id: row['id'] as String,
        vehicleId: row['vehicle_id'] as String,
        tireSetId: row['tire_set_id'] as String,
        mountedDate: DateTime.parse(row['mounted_date'] as String),
        mountedMileage: row['mounted_mileage'] as int,
        unmountedDate: row['unmounted_date'] == null
            ? null
            : DateTime.parse(row['unmounted_date'] as String),
        unmountedMileage: row['unmounted_mileage'] as int?,
      );
    }).toList();
  }

  Future<void> deleteTireMountHistoriesForTireSet(String tireSetId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('tire_mount_history_cloud')
        .delete()
        .eq('tire_set_id', tireSetId)
        .eq('user_id', user.id);
  }

  Future<void> deleteTireMountHistory(String historyId) async {
    await _requirePremium();

    final user = _currentUser!;

    await _supabase
        .from('tire_mount_history_cloud')
        .delete()
        .eq('id', historyId)
        .eq('user_id', user.id);
  }

  // ---------------------------------------------------------------------------
  // DOKUMENTE
  // ---------------------------------------------------------------------------

  Future<void> uploadDocument(VehicleDocument document) async {
    await _requirePremium();

    final user = _currentUser!;

    String? storagePath;

    final localFilePath = document.filePath;

    if (localFilePath != null && localFilePath.trim().isNotEmpty) {
      final resolvedFilePath = await _documentStorageService.resolveFilePath(
        localFilePath,
      );

      if (resolvedFilePath != null) {
        final file = File(resolvedFilePath);

        if (await file.exists()) {
          final originalFileName = path.basename(resolvedFilePath);

          storagePath = '${user.id}/${document.id}/$originalFileName';

          await _supabase.storage
              .from(_documentBucket)
              .upload(
                storagePath,
                file,
                fileOptions: const FileOptions(upsert: true),
              );
        }
      }
    }

    await _supabase.from('vehicle_documents_cloud').upsert({
      'id': document.id,
      'user_id': user.id,
      'vehicle_id': document.vehicleId,
      'title': document.title,
      'category': document.category,
      'date': document.date.toIso8601String(),
      'notes': document.notes,
      'storage_path': storagePath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> uploadDocuments(List<VehicleDocument> documents) async {
    await _requirePremium();

    if (documents.isEmpty) {
      return;
    }

    for (final document in documents) {
      await uploadDocument(document);
    }
  }

  Future<List<VehicleDocument>> downloadDocuments() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('vehicle_documents_cloud')
        .select()
        .eq('user_id', user.id)
        .order('date');

    final documents = <VehicleDocument>[];

    for (final row in rows) {
      final storagePath = row['storage_path'] as String?;

      String? localFilePath;

      if (storagePath != null && storagePath.trim().isNotEmpty) {
        final bytes = await _supabase.storage
            .from(_documentBucket)
            .download(storagePath);

        localFilePath = await _documentStorageService.saveCloudFile(
          bytes: bytes,
          originalFileName: path.basename(storagePath),
        );
      }

      documents.add(
        VehicleDocument(
          id: row['id'] as String,
          vehicleId: row['vehicle_id'] as String,
          title: row['title'] as String,
          category: row['category'] as String,
          date: DateTime.parse(row['date'] as String),
          filePath: localFilePath,
          notes: row['notes'] as String?,
        ),
      );
    }

    return documents;
  }

  Future<void> deleteDocument(String documentId) async {
    await _requirePremium();

    final user = _currentUser!;

    final row = await _supabase
        .from('vehicle_documents_cloud')
        .select('storage_path')
        .eq('id', documentId)
        .eq('user_id', user.id)
        .maybeSingle();

    final storagePath = row?['storage_path'] as String?;

    if (storagePath != null && storagePath.trim().isNotEmpty) {
      await _supabase.storage.from(_documentBucket).remove([storagePath]);
    }

    await _supabase
        .from('vehicle_documents_cloud')
        .delete()
        .eq('id', documentId)
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

  Future<int> getCloudExpenseCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('expenses_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudMaintenanceEntryCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('maintenance_entries_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudMaintenanceWorkCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('maintenance_works_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudTireSetCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('tire_sets_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudTireMountHistoryCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('tire_mount_history_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }

  Future<int> getCloudDocumentCount() async {
    await _requirePremium();

    final user = _currentUser!;

    final rows = await _supabase
        .from('vehicle_documents_cloud')
        .select('id')
        .eq('user_id', user.id);

    return rows.length;
  }
}
