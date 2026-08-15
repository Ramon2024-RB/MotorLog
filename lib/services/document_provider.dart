import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../models/vehicle_document.dart';

final documentProvider =
    AsyncNotifierProvider<DocumentNotifier, List<VehicleDocument>>(
      DocumentNotifier.new,
    );

class DocumentNotifier extends AsyncNotifier<List<VehicleDocument>> {
  @override
  Future<List<VehicleDocument>> build() async {
    return AppDatabase.instance.getDocuments();
  }

  Future<void> reload() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return AppDatabase.instance.getDocuments();
    });
  }

  Future<void> addDocument(VehicleDocument document) async {
    await AppDatabase.instance.insertDocument(document);
    await reload();
  }

  Future<void> updateDocument(VehicleDocument document) async {
    await AppDatabase.instance.updateDocument(document);
    await reload();
  }

  Future<void> deleteDocument(String id) async {
    await AppDatabase.instance.deleteDocument(id);
    await reload();
  }
}
