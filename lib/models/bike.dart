import 'dart:convert';

/// Modelo de bicicleta para el Garaje y Odometría por vehículo
class Bike {
  final String id;
  final String name;
  final String brandModel;
  final String specs;
  final String type; // 'Carretera', 'Gravel', 'MTB'
  final double totalDistanceKm;
  final double totalElevationM;
  final int totalSessions;
  final double chainWearPct;
  final double tireWearPct;
  final double brakeWearPct;
  final bool isDefault;

  Bike({
    required this.id,
    required this.name,
    required this.brandModel,
    required this.specs,
    required this.type,
    this.totalDistanceKm = 0.0,
    this.totalElevationM = 0.0,
    this.totalSessions = 0,
    this.chainWearPct = 78.0,
    this.tireWearPct = 62.0,
    this.brakeWearPct = 85.0,
    this.isDefault = false,
  });

  Bike copyWith({
    String? id,
    String? name,
    String? brandModel,
    String? specs,
    String? type,
    double? totalDistanceKm,
    double? totalElevationM,
    int? totalSessions,
    double? chainWearPct,
    double? tireWearPct,
    double? brakeWearPct,
    bool? isDefault,
  }) {
    return Bike(
      id: id ?? this.id,
      name: name ?? this.name,
      brandModel: brandModel ?? this.brandModel,
      specs: specs ?? this.specs,
      type: type ?? this.type,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalElevationM: totalElevationM ?? this.totalElevationM,
      totalSessions: totalSessions ?? this.totalSessions,
      chainWearPct: chainWearPct ?? this.chainWearPct,
      tireWearPct: tireWearPct ?? this.tireWearPct,
      brakeWearPct: brakeWearPct ?? this.brakeWearPct,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brandModel': brandModel,
      'specs': specs,
      'type': type,
      'totalDistanceKm': totalDistanceKm,
      'totalElevationM': totalElevationM,
      'totalSessions': totalSessions,
      'chainWearPct': chainWearPct,
      'tireWearPct': tireWearPct,
      'brakeWearPct': brakeWearPct,
      'isDefault': isDefault,
    };
  }

  factory Bike.fromMap(Map<String, dynamic> map) {
    return Bike(
      id: map['id'] as String,
      name: map['name'] as String,
      brandModel: map['brandModel'] as String? ?? '',
      specs: map['specs'] as String? ?? '',
      type: map['type'] as String? ?? 'Carretera',
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalElevationM: (map['totalElevationM'] as num?)?.toDouble() ?? 0.0,
      totalSessions: map['totalSessions'] as int? ?? 0,
      chainWearPct: (map['chainWearPct'] as num?)?.toDouble() ?? 75.0,
      tireWearPct: (map['tireWearPct'] as num?)?.toDouble() ?? 60.0,
      brakeWearPct: (map['brakeWearPct'] as num?)?.toDouble() ?? 80.0,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Bike.fromJson(String source) => Bike.fromMap(jsonDecode(source));
}
