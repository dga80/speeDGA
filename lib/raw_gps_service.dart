import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Modelo de datos GPS unificado
class RawGpsData {
  final double latitude;
  final double longitude;
  final double speed; // m/s
  final double accuracy;
  final double altitude;
  final double bearing;
  final int timestamp;
  final int satelliteCount;
  final String provider;

  RawGpsData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.altitude,
    required this.bearing,
    required this.timestamp,
    required this.satelliteCount,
    required this.provider,
  });

  factory RawGpsData.fromMap(Map<dynamic, dynamic> map) {
    return RawGpsData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      bearing: (map['bearing'] as num).toDouble(),
      timestamp: map['timestamp'] as int,
      satelliteCount: map['satelliteCount'] as int,
      provider: map['provider'] as String,
    );
  }

  /// Velocidad en km/h
  double get speedKmh => speed * 3.6;
}

/// Servicio GPS híbrido: utiliza sensor nativo Android en APK y Geolocator HTML5 en Web (Netlify)
class RawGpsService {
  static const MethodChannel _methodChannel = MethodChannel('raw_gps/method');
  static const EventChannel _eventChannel = EventChannel('raw_gps/location');

  Stream<RawGpsData>? _locationStream;
  StreamController<RawGpsData>? _locationController;
  StreamSubscription? _eventSubscription;
  StreamSubscription<Position>? _geolocatorSubscription;

  int _currentSatelliteCount = 0;
  int get satelliteCount => _currentSatelliteCount;

  Stream<RawGpsData> get locationStream {
    if (_locationStream != null) {
      return _locationStream!;
    }

    _locationController = StreamController<RawGpsData>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );

    _locationStream = _locationController!.stream;
    return _locationStream!;
  }

  void _startListening() async {
    // Si estamos en la Web (Netlify), usar directamente la API de Geolocalización del navegador
    if (kIsWeb) {
      _startGeolocatorFallback('browser_web');
      return;
    }

    // En Android nativo, intentar usar el plugin de bajo nivel RawGpsPlugin
    try {
      await _methodChannel.invokeMethod('startLocationUpdates');

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            if (event.containsKey('latitude')) {
              final gpsData = RawGpsData.fromMap(event);
              _currentSatelliteCount = gpsData.satelliteCount;
              _locationController?.add(gpsData);
            } else if (event['event'] == 'gnss_status') {
              _currentSatelliteCount = event['satelliteCount'] as int;
            }
          }
        },
        onError: (error) {
          // Si el canal nativo falla, conmutar transparentemente a Geolocator
          _startGeolocatorFallback('native_stream_error');
        },
      );
    } catch (e) {
      // Si el plugin nativo no existe (MissingPluginException), conmutar a Geolocator
      _startGeolocatorFallback('native_unsupported');
    }
  }

  /// Conmutación automática al motor de Geolocalización estándar
  void _startGeolocatorFallback(String source) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _geolocatorSubscription?.cancel();
    _geolocatorSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        final speedMs = position.speed < 0 ? 0.0 : position.speed;
        _currentSatelliteCount = 8; // Indicador representativo para web/geolocator
        
        final gpsData = RawGpsData(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: speedMs,
          accuracy: position.accuracy,
          altitude: position.altitude,
          bearing: position.heading,
          timestamp: position.timestamp.millisecondsSinceEpoch,
          satelliteCount: _currentSatelliteCount,
          provider: source,
        );

        _locationController?.add(gpsData);
      },
      onError: (e) {
        _locationController?.addError(e);
      },
    );
  }

  void _stopListening() async {
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;

      await _geolocatorSubscription?.cancel();
      _geolocatorSubscription = null;

      if (!kIsWeb) {
        await _methodChannel.invokeMethod('stopLocationUpdates');
      }
    } catch (_) {}
  }

  Future<int> getSatelliteCount() async {
    if (kIsWeb) return 8;
    try {
      final count = await _methodChannel.invokeMethod<int>('getSatelliteCount');
      return count ?? 8;
    } catch (_) {
      return 8;
    }
  }

  void dispose() {
    _stopListening();
    _locationController?.close();
    _locationController = null;
    _locationStream = null;
  }
}
