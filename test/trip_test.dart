import 'package:flutter_test/flutter_test.dart';
import 'package:speeDGA/models/trip.dart';
import 'package:speeDGA/services/gpx_service.dart';

void main() {
  group('Trip and TripPoint Models', () {
    test('TripPoint serializes and deserializes correctly', () {
      final point = TripPoint(
        latitude: 41.3851,
        longitude: 2.1734,
        altitude: 45.5,
        speedKmh: 24.8,
        timestamp: DateTime(2026, 9, 1, 10, 0, 0),
      );

      final map = point.toMap();
      expect(map['lat'], 41.3851);
      expect(map['lng'], 2.1734);
      expect(map['alt'], 45.5);
      expect(map['speed'], 24.8);

      final fromMap = TripPoint.fromMap(map);
      expect(fromMap.latitude, 41.3851);
      expect(fromMap.longitude, 2.1734);
      expect(fromMap.altitude, 45.5);
      expect(fromMap.speedKmh, 24.8);
    });

    test('Trip serializes to and from SQLite map correctly', () {
      final now = DateTime.now();
      final points = [
        TripPoint(latitude: 41.38, longitude: 2.17, altitude: 50.0, speedKmh: 20.0),
        TripPoint(latitude: 41.39, longitude: 2.18, altitude: 65.0, speedKmh: 25.0),
      ];

      final trip = Trip(
        id: 1,
        fechaRegistro: now,
        distanciaKm: 12.5,
        velocidadMaxKmh: 42.1,
        velocidadMediaKmh: 23.4,
        tiempoTotalSeg: 2100,
        tiempoMovimientoSeg: 1950,
        desnivelPositivoM: 280.0,
        desnivelNegativoM: 260.0,
        rutaCoordenadas: points,
      );

      final map = trip.toMap();
      expect(map['id'], 1);
      expect(map['distancia_km'], 12.5);
      expect(map['velocidad_max_kmh'], 42.1);
      expect(map['velocidad_media_kmh'], 23.4);
      expect(map['desnivel_positivo_m'], 280.0);

      final restoredTrip = Trip.fromMap(map);
      expect(restoredTrip.id, 1);
      expect(restoredTrip.distanciaKm, 12.5);
      expect(restoredTrip.rutaCoordenadas.length, 2);
      expect(restoredTrip.rutaCoordenadas[0].latitude, 41.38);
      expect(restoredTrip.rutaCoordenadas[1].altitude, 65.0);
    });

    test('Trip time formatting handles hours and minutes', () {
      final tripWithHours = Trip(
        fechaRegistro: DateTime.now(),
        distanciaKm: 45.0,
        velocidadMaxKmh: 50.0,
        velocidadMediaKmh: 25.0,
        tiempoTotalSeg: 7500, // 2h 05m 00s
        tiempoMovimientoSeg: 7230, // 2h 00m 30s
        rutaCoordenadas: [],
      );

      expect(tripWithHours.formattedMovingTime, '2:00:30');

      final tripMinutesOnly = Trip(
        fechaRegistro: DateTime.now(),
        distanciaKm: 5.0,
        velocidadMaxKmh: 25.0,
        velocidadMediaKmh: 20.0,
        tiempoTotalSeg: 900, // 15m 00s
        tiempoMovimientoSeg: 870, // 14m 30s
        rutaCoordenadas: [],
      );

      expect(tripMinutesOnly.formattedMovingTime, '14:30');
    });
  });

  group('GpxService', () {
    test('generateGpx produces valid GPX 1.1 XML structure for Strava/Garmin', () {
      final trip = Trip(
        id: 42,
        fechaRegistro: DateTime.utc(2026, 9, 1, 12, 0, 0),
        distanciaKm: 15.2,
        velocidadMaxKmh: 35.0,
        velocidadMediaKmh: 22.0,
        tiempoTotalSeg: 2500,
        tiempoMovimientoSeg: 2400,
        desnivelPositivoM: 150.0,
        rutaCoordenadas: [
          TripPoint(
            latitude: 41.3851,
            longitude: 2.1734,
            altitude: 40.0,
            speedKmh: 21.6, // 6.0 m/s
            timestamp: DateTime.utc(2026, 9, 1, 12, 0, 5),
          ),
          TripPoint(
            latitude: 41.3860,
            longitude: 2.1745,
            altitude: 45.0,
            speedKmh: 25.2, // 7.0 m/s
            timestamp: DateTime.utc(2026, 9, 1, 12, 0, 10),
          ),
        ],
      );

      final xml = GpxService.generateGpx(trip);

      expect(xml.contains('<?xml version="1.0" encoding="UTF-8"?>'), isTrue);
      expect(xml.contains('<gpx version="1.1"'), isTrue);
      expect(xml.contains('<type>Cycling</type>'), isTrue);
      expect(xml.contains('<trkpt lat="41.3851" lon="2.1734">'), isTrue);
      expect(xml.contains('<ele>40.0</ele>'), isTrue);
      expect(xml.contains('<speed>6.00</speed>'), isTrue);
      expect(xml.contains('</trkpt>'), isTrue);
      expect(xml.contains('</gpx>'), isTrue);
    });
  });
}
