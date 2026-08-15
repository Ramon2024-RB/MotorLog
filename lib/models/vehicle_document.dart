class VehicleDocument {
  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.category,
    required this.date,
    this.filePath,
    this.notes,
  });

  final String id;
  final String vehicleId;

  /// Name des Dokuments,
  /// zum Beispiel "TÜV Bericht 2026".
  final String title;

  /// Kategorie des Dokuments,
  /// zum Beispiel Rechnung, TÜV, Versicherung oder Fahrzeugschein.
  final String category;

  /// Datum des Dokuments.
  final DateTime date;

  /// Lokaler Pfad zur gespeicherten Datei.
  /// Bleibt null, solange noch keine Datei angehängt wurde.
  final String? filePath;

  /// Optionale Notizen zum Dokument.
  final String? notes;

  VehicleDocument copyWith({
    String? id,
    String? vehicleId,
    String? title,
    String? category,
    DateTime? date,
    String? filePath,
    String? notes,
  }) {
    return VehicleDocument(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      filePath: filePath ?? this.filePath,
      notes: notes ?? this.notes,
    );
  }

  factory VehicleDocument.fromMap(Map<String, dynamic> map) {
    return VehicleDocument(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      filePath: map['file_path'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'file_path': filePath,
      'notes': notes,
    };
  }
}
