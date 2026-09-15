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

  Timer? _nativeWatchdogTimer;
  bool _receivedNativeFix = false;

  // Variables para cálculo de velocidad si el sensor o navegador devuelve 0.0
  double? _lastLat;
  double? _lastLng;
  int? _lastTimeMs;

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

    _receivedNativeFix = false;

    // En Android nativo, intentar usar el plugin de bajo nivel RawGpsPlugin
    try {
      await _methodChannel.invokeMethod('startLocationUpdates');

      // Watchdog: si en 2.5 segundos el GPS nativo no ha emitido ninguna posición
      // (por ejemplo en interiores o mientras adquiere satélites), arrancar Geolocator en paralelo
      _nativeWatchdogTimer?.cancel();
      _nativeWatchdogTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!_receivedNativeFix) {
          _startGeolocatorFallback('native_watchdog_fallback');
        }
      });

      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            if (event.containsKey('latitude')) {
              _receivedNativeFix = true;
              _nativeWatchdogTimer?.cancel();
              // Si ya había fallback de Geolocator activo, cancelarlo para dar prioridad al GPS nativo
              if (_geolocatorSubscription != null) {
                _geolocatorSubscription?.cancel();
                _geolocatorSubscription = null;
              }

              final rawData = RawGpsData.fromMap(event);
              _currentSatelliteCount = rawData.satelliteCount;

              // Asegurar cálculo de velocidad si el sensor entrega 0.0 en movimiento
              double speed = rawData.speed;
              final nowMs = rawData.timestamp;
              if (speed <= 0.0 && _lastLat != null && _lastLng != null && _lastTimeMs != null) {
                final dt = (nowMs - _lastTimeMs!) / 1000.0;
                if (dt > 0.3 && dt < 10.0) {
                  final d = Geolocator.distanceBetween(_lastLat!, _lastLng!, rawData.latitude, rawData.longitude);
                  if (d > 0.6) {
                    speed = d / dt;
                  }
                }
              }

              _lastLat = rawData.latitude;
              _lastLng = rawData.longitude;
              _lastTimeMs = nowMs;

              final correctedData = RawGpsData(
                latitude: rawData.latitude,
                longitude: rawData.longitude,
                speed: speed,
                accuracy: rawData.accuracy,
                altitude: rawData.altitude,
                bearing: rawData.bearing,
                timestamp: rawData.timestamp,
                satelliteCount: rawData.satelliteCount,
                provider: rawData.provider,
              );

              _locationController?.add(correctedData);
            } else if (event['event'] == 'gnss_status') {
              _currentSatelliteCount = event['satelliteCount'] as int;
            }
          }
        },
        onError: (error) {
          _startGeolocatorFallback('native_stream_error');
        },
      );
    } catch (e) {
      _startGeolocatorFallback('native_unsupported');
    }
  }

  /// Conmutación automática al motor de Geolocalización estándar
  void _startGeolocatorFallback(String source) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _geolocatorSubscription?.cancel();
    _geolocatorSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        double speedMs = position.speed < 0 ? 0.0 : position.speed;
        final nowMs = position.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

        // Calcular velocidad por distancia recorrida si el sensor devuelve 0.0
        if (speedMs <= 0.0 && _lastLat != null && _lastLng != null && _lastTimeMs != null) {
          final timeDiffSec = (nowMs - _lastTimeMs!) / 1000.0;
          if (timeDiffSec > 0.3 && timeDiffSec < 10.0) {
            final distMeters = Geolocator.distanceBetween(
              _lastLat!,
              _lastLng!,
              position.latitude,
              position.longitude,
            );
            if (distMeters > 0.6) {
              speedMs = distMeters / timeDiffSec;
            }
          }
        }

        _lastLat = position.latitude;
        _lastLng = position.longitude;
        _lastTimeMs = nowMs;

        if (_currentSatelliteCount == 0) {
          _currentSatelliteCount = 8;
        }

        final gpsData = RawGpsData(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: speedMs,
          accuracy: position.accuracy,
          altitude: position.altitude,
          bearing: position.heading,
          timestamp: nowMs,
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
      _nativeWatchdogTimer?.cancel();
      _nativeWatchdogTimer = null;

      await _eventSubscription?.cancel();
      _eventSubscription = null;

      await _geolocatorSubscription?.cancel();
      _geolocatorSubscription = null;

      _lastLat = null;
      _lastLng = null;
      _lastTimeMs = null;

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
