import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';

/// Gestor Singleton híbrido para persistencia de datos:
/// - En Android/iOS/Desktop: utiliza SQLite local de alto rendimiento (sqflite).
/// - En Web (Netlify): utiliza localStorage persistente mediante SharedPreferences.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _webStorageKey = 'speedga_trips_web_data';

  DatabaseHelper._init();

  /// Inicializa el motor de almacenamiento adecuado según la plataforma
  Future<void> init() async {
    if (kIsWeb) {
      await SharedPreferences.getInstance();
    } else {
      await database;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('speedga.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_registro TEXT NOT NULL,
        distancia_km REAL NOT NULL DEFAULT 0.0,
        velocidad_max_kmh REAL NOT NULL DEFAULT 0.0,
        velocidad_media_kmh REAL NOT NULL DEFAULT 0.0,
        tiempo_total_seg INTEGER NOT NULL DEFAULT 0,
        tiempo_movimiento_seg INTEGER NOT NULL DEFAULT 0,
        desnivel_positivo_m REAL NOT NULL DEFAULT 0.0,
        desnivel_negativo_m REAL NOT NULL DEFAULT 0.0,
        ruta_coordenadas_json TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_trips_fecha ON trips (fecha_registro DESC)
    ''');
  }

  /// Inserta un nuevo trayecto
  Future<int> insertTrip(Trip trip) async {
    if (kIsWeb) {
      return await _insertTripWeb(trip);
    }

    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  /// Obtiene todos los trayectos ordenados cronológicamente inverso
  Future<List<Trip>> getTrips() async {
    if (kIsWeb) {
      return await _getTripsWeb();
    }

    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'fecha_registro DESC');
    return result.map((map) => Trip.fromMap(map)).toList();
  }

  /// Obtiene un trayecto específico por su ID
  Future<Trip?> getTripById(int id) async {
    if (kIsWeb) {
      final trips = await _getTripsWeb();
      try {
        return trips.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }

    final db = await instance.database;
    final maps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  /// Elimina un trayecto por su ID
  Future<int> deleteTrip(int id) async {
    if (kIsWeb) {
      return await _deleteTripWeb(id);
    }

    final db = await instance.database;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todos los trayectos
  Future<int> deleteAllTrips() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webStorageKey);
      return 1;
    }

    final db = await instance.database;
    return await db.delete('trips');
  }

  /// Obtiene estadísticas acumuladas del ciclista
  Future<Map<String, dynamic>> getGlobalStats() async {
    if (kIsWeb) {
      return await _getGlobalStatsWeb();
    }

    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(id) AS total_salidas,
        COALESCE(SUM(distancia_km), 0.0) AS total_km,
        COALESCE(MAX(velocidad_max_kmh), 0.0) AS max_velocidad,
        COALESCE(SUM(desnivel_positivo_m), 0.0) AS total_desnivel,
        COALESCE(SUM(tiempo_movimiento_seg), 0) AS total_tiempo_seg
      FROM trips
    ''');

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'totalSalidas': row['total_salidas'] as int? ?? 0,
        'totalKm': (row['total_km'] as num?)?.toDouble() ?? 0.0,
        'maxVelocidad': (row['max_velocidad'] as num?)?.toDouble() ?? 0.0,
        'totalDesnivel': (row['total_desnivel'] as num?)?.toDouble() ?? 0.0,
        'totalTiempoSeg': row['total_tiempo_seg'] as int? ?? 0,
      };
    }

    return {
      'totalSalidas': 0,
      'totalKm': 0.0,
      'maxVelocidad': 0.0,
      'totalDesnivel': 0.0,
      'totalTiempoSeg': 0,
    };
  }

  // =================== Implementación Específica Web ===================

  Future<List<Trip>> _getTripsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_webStorageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List decoded = jsonDecode(jsonStr);
      final trips = decoded.map((m) => Trip.fromMap(Map<String, dynamic>.from(m))).toList();
      trips.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      return trips;
    } catch (_) {
      return [];
    }
  }

  Future<int> _insertTripWeb(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();
    final trips = await _getTripsWeb();
    
    int nextId = 1;
    if (trips.isNotEmpty) {
      final maxId = trips.map((t) => t.id ?? 0).reduce(max);
      nextId = maxId + 1;
    }

    final newTripMap = trip.toMap();
    newTripMap['id'] = nextId;

    final updatedMaps = trips.map((t) => t.toMap()).toList();
    updatedMaps.insert(0, newTripMap);

    await prefs.setString(_webStorageKey, jsonEncode(updatedMaps));
    return nextId;
  }

  Future<int> _deleteTripWeb(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final trips = await _getTripsWeb();
    trips.removeWhere((t) => t.id == id);
    await prefs.setString(_webStorageKey, jsonEncode(trips.map((t) => t.toMap()).toList()));
    return 1;
  }

  Future<Map<String, dynamic>> _getGlobalStatsWeb() async {
    final trips = await _getTripsWeb();
    if (trips.isEmpty) {
      return {
        'totalSalidas': 0,
        'totalKm': 0.0,
        'maxVelocidad': 0.0,
        'totalDesnivel': 0.0,
        'totalTiempoSeg': 0,
      };
    }

    double totalKm = 0.0;
    double maxVel = 0.0;
    double totalDesnivel = 0.0;
    int totalTiempo = 0;

    for (final t in trips) {
      totalKm += t.distanciaKm;
      if (t.velocidadMaxKmh > maxVel) maxVel = t.velocidadMaxKmh;
      totalDesnivel += t.desnivelPositivoM;
      totalTiempo += t.tiempoMovimientoSeg;
    }

    return {
      'totalSalidas': trips.length,
      'totalKm': totalKm,
      'maxVelocidad': maxVel,
      'totalDesnivel': totalDesnivel,
      'totalTiempoSeg': totalTiempo,
    };
  }

  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      final db = await instance.database;
      db.close();
      _database = null;
    }
  }
}
