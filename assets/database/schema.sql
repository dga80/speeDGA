-- Esquema SQL de speeDGA para SQLite
-- Este archivo define la estructura de la base de datos local versionada en el repositorio.

CREATE TABLE IF NOT EXISTS trips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_registro TEXT NOT NULL,             -- ISO 8601 String (e.g. 2026-09-01T21:00:00Z)
    distancia_km REAL NOT NULL DEFAULT 0.0,    -- Distancia total en kilómetros
    velocidad_max_kmh REAL NOT NULL DEFAULT 0.0, -- Velocidad punta alcanzada en km/h
    velocidad_media_kmh REAL NOT NULL DEFAULT 0.0, -- Velocidad media en movimiento en km/h
    tiempo_total_seg INTEGER NOT NULL DEFAULT 0,  -- Tiempo total transcurrido en segundos
    tiempo_movimiento_seg INTEGER NOT NULL DEFAULT 0, -- Tiempo real en pedaleo (auto-pause)
    desnivel_positivo_m REAL NOT NULL DEFAULT 0.0, -- Metros ascendidos (+D)
    desnivel_negativo_m REAL NOT NULL DEFAULT 0.0, -- Metros descendidos (-D)
    ruta_coordenadas_json TEXT                 -- Coordenadas de la ruta en formato JSON
);

-- Índice para acelerar la carga del historial en orden cronológico inverso
CREATE INDEX IF NOT EXISTS idx_trips_fecha ON trips (fecha_registro DESC);
