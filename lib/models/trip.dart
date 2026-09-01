import 'dart:convert';

/// Punto individual de una ruta GPS con telemetría
class TripPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speedKmh;
  final DateTime timestamp;

  TripPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speedKmh = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'lat': latitude,
      'lng': longitude,
      'alt': altitude,
      'speed': speedKmh,
      'time': timestamp.toIso8601String(),
    };
  }

  factory TripPoint.fromMap(Map<String, dynamic> map) {
    return TripPoint(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      altitude: (map['alt'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (map['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['time'] != null
          ? DateTime.tryParse(map['time']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Modelo que representa una salida o trayecto en bicicleta
class Trip {
  final int? id;
  final DateTime fechaRegistro;
  final double distanciaKm;
  final double velocidadMaxKmh;
  final double velocidadMediaKmh;
  final int tiempoTotalSeg;
  final int tiempoMovimientoSeg;
  final double desnivelPositivoM;
  final double desnivelNegativoM;
  final List<TripPoint> rutaCoordenadas;

  Trip({
    this.id,
    required this.fechaRegistro,
    required this.distanciaKm,
    required this.velocidadMaxKmh,
    required this.velocidadMediaKmh,
    required this.tiempoTotalSeg,
    required this.tiempoMovimientoSeg,
    this.desnivelPositivoM = 0.0,
    this.desnivelNegativoM = 0.0,
    required this.rutaCoordenadas,
  });

  /// Convierte el modelo en un mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'distancia_km': distanciaKm,
      'velocidad_max_kmh': velocidadMaxKmh,
      'velocidad_media_kmh': velocidadMediaKmh,
      'tiempo_total_seg': tiempoTotalSeg,
      'tiempo_movimiento_seg': tiempoMovimientoSeg,
      'desnivel_positivo_m': desnivelPositivoM,
      'desnivel_negativo_m': desnivelNegativoM,
      'ruta_coordenadas_json': jsonEncode(
        rutaCoordenadas.map((p) => p.toMap()).toList(),
      ),
    };
  }

  /// Crea un objeto Trip a partir de una fila de SQLite
  factory Trip.fromMap(Map<String, dynamic> map) {
    List<TripPoint> points = [];
    if (map['ruta_coordenadas_json'] != null) {
      try {
        final decoded = jsonDecode(map['ruta_coordenadas_json'] as String);
        if (decoded is List) {
          points = decoded
              .map((item) => TripPoint.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        }
      } catch (_) {
        points = [];
      }
    }

    return Trip(
      id: map['id'] as int?,
      fechaRegistro: DateTime.tryParse(map['fecha_registro'] as String? ?? '') ?? DateTime.now(),
      distanciaKm: (map['distancia_km'] as num?)?.toDouble() ?? 0.0,
      velocidadMaxKmh: (map['velocidad_max_kmh'] as num?)?.toDouble() ?? 0.0,
      velocidadMediaKmh: (map['velocidad_media_kmh'] as num?)?.toDouble() ?? 0.0,
      tiempoTotalSeg: map['tiempo_total_seg'] as int? ?? 0,
      tiempoMovimientoSeg: map['tiempo_movimiento_seg'] as int? ?? 0,
      desnivelPositivoM: (map['desnivel_positivo_m'] as num?)?.toDouble() ?? 0.0,
      desnivelNegativoM: (map['desnivel_negativo_m'] as num?)?.toDouble() ?? 0.0,
      rutaCoordenadas: points,
    );
  }

  /// Formato legible del tiempo en movimiento
  String get formattedMovingTime {
    final duration = Duration(seconds: tiempoMovimientoSeg);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Formato legible del tiempo total
  String get formattedTotalTime {
    final duration = Duration(seconds: tiempoTotalSeg);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
