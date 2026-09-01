import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';

/// Gestor Singleton para la base de datos local SQLite de speeDGA
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('speedga.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

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

  /// Inserta un nuevo trayecto en la base de datos local
  Future<int> insertTrip(Trip trip) async {
    final db = await instance.database;
    return await db.insert('trips', trip.toMap());
  }

  /// Obtiene todos los trayectos ordenados por fecha descendente
  Future<List<Trip>> getTrips() async {
    final db = await instance.database;
    final result = await db.query('trips', orderBy: 'fecha_registro DESC');
    return result.map((map) => Trip.fromMap(map)).toList();
  }

  /// Obtiene un trayecto específico por su ID
  Future<Trip?> getTripById(int id) async {
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
    final db = await instance.database;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina todos los trayectos
  Future<int> deleteAllTrips() async {
    final db = await instance.database;
    return await db.delete('trips');
  }

  /// Obtiene estadísticas acumuladas de la bicicleta
  Future<Map<String, dynamic>> getGlobalStats() async {
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

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
