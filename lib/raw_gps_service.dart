import 'dart:async';
import 'package:flutter/services.dart';

/// Raw GPS data model
class RawGpsData {
  final double latitude;
  final double longitude;
  final double speed; // m/s - RAW speed from GPS sensor
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

  /// Get speed in km/h
  double get speedKmh => speed * 3.6;
}

/// Service for accessing raw GPS data via native Android LocationManager
class RawGpsService {
  static const MethodChannel _methodChannel = MethodChannel('raw_gps/method');
  static const EventChannel _eventChannel = EventChannel('raw_gps/location');

  Stream<RawGpsData>? _locationStream;
  StreamController<RawGpsData>? _locationController;
  StreamSubscription? _eventSubscription;

  int _currentSatelliteCount = 0;

  /// Get the current satellite count
  int get satelliteCount => _currentSatelliteCount;

  /// Start receiving raw GPS location updates
  /// 
  /// This uses Android's GPS_PROVIDER with:
  /// - minTimeMs = 0 (maximum update frequency)
  /// - minDistanceM = 0 (no distance filter)
  /// 
  /// Returns a stream of raw, unfiltered GPS data
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
    try {
      // Start location updates on native side
      await _methodChannel.invokeMethod('startLocationUpdates');

      // Listen to location events
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            // Check if it's a location update or a status event
            if (event.containsKey('latitude')) {
              final gpsData = RawGpsData.fromMap(event);
              _currentSatelliteCount = gpsData.satelliteCount;
              _locationController?.add(gpsData);
            } else if (event['event'] == 'gnss_status') {
              // Update satellite count from GNSS status
              _currentSatelliteCount = event['satelliteCount'] as int;
            }
            // Ignore other events like provider_enabled, gnss_started, etc.
          }
        },
        onError: (error) {
          print('❌ Raw GPS Stream Error: $error');
          _locationController?.addError(error);
        },
      );
    } catch (e) {
      print('❌ Failed to start raw GPS: $e');
      _locationController?.addError(e);
    }
  }

  void _stopListening() async {
    try {
      await _eventSubscription?.cancel();
      await _methodChannel.invokeMethod('stopLocationUpdates');
      _eventSubscription = null;
    } catch (e) {
      print('⚠️ Error stopping GPS: $e');
    }
  }

  /// Get current satellite count
  Future<int> getSatelliteCount() async {
    try {
      final count = await _methodChannel.invokeMethod<int>('getSatelliteCount');
      return count ?? 0;
    } catch (e) {
      print('⚠️ Error getting satellite count: $e');
      return 0;
    }
  }

  /// Dispose the service
  void dispose() {
    _stopListening();
    _locationController?.close();
    _locationController = null;
    _locationStream = null;
  }
}
