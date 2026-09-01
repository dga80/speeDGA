import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'history_screen.dart';
import 'models/trip.dart';
import 'raw_gps_service.dart';
import 'services/database_helper.dart';
import 'weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar zona horaria
  tz.initializeTimeZones();
  try {
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  } catch (e) {
    // Fallback a Barcelona si falla
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
  }

  // Inicializar la base de datos local SQLite (sin servidores, nunca se desactiva)
  await DatabaseHelper.instance.database;

  runApp(const SpeeDGAApp());
}

class SpeeDGAApp extends StatelessWidget {
  const SpeeDGAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'speeDGA - Ciclocomputador',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF41),
          surface: Colors.black,
        ),
      ),
      home: const SpeedometerPage(),
    );
  }
}

class SpeedometerPage extends StatefulWidget {
  const SpeedometerPage({super.key});

  @override
  State<SpeedometerPage> createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<SpeedometerPage> {
  // --- Métricas de Telemetría Ciclista ---
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  double _totalDistance = 0.0;
  double _elevationGain = 0.0;
  double _elevationLoss = 0.0;
  double? _lastAltitude;

  bool _isTracking = false;
  bool _isAutoPaused = false;
  int _consecutiveZeroSpeedTicks = 0;

  DateTime? _startTime;
  int _totalSeconds = 0;
  int _movingSeconds = 0;
  Timer? _timer;

  double? _lastLatitude;
  double? _lastLongitude;
  StreamSubscription<RawGpsData>? _gpsStream;
  RawGpsService? _rawGpsService;
  final List<TripPoint> _routePoints = [];
  int _satelliteCount = 0;
  bool _gpsServiceInitialized = false;

  // --- Clima Ciclista (Temp & Viento) ---
  final WeatherService _weatherService = WeatherService();
  double? _currentTemp;
  int? _weatherCode;
  double? _windSpeed;
  String? _windDirection;
  bool _weatherError = false;
  DateTime? _lastWeatherUpdate;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    try {
      _rawGpsService = RawGpsService();
      _gpsServiceInitialized = true;
    } catch (e) {
      _gpsServiceInitialized = false;
    }

    await _checkPermissions();
    WakelockPlus.enable();
    _loadInitialWeather();
  }

  Future<void> _loadInitialWeather() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('GPS timeout'),
      );

      await _fetchWeather(position.latitude, position.longitude);
    } catch (_) {
      if (mounted) {
        setState(() {
          _weatherError = true;
        });
      }
    }
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog(
        '📍 Ubicación Desactivada',
        'Los servicios de ubicación están desactivados en tu dispositivo. Por favor, actívalos para usar speeDGA.',
      );
      return;
    }

    PermissionStatus status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      _showDialog(
        '🔒 Permiso Bloqueado',
        'Los permisos de ubicación están bloqueados permanentemente. Actívalos en ajustes para poder registrar rutas.',
      );
      return;
    }

    LocationPermission geoPermission = await Geolocator.checkPermission();
    if (geoPermission == LocationPermission.denied) {
      geoPermission = await Geolocator.requestPermission();
    }

    if (status.isGranted && geoPermission != LocationPermission.denied) {
      _showSnack('✅ GPS y permisos listos para rodar');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        backgroundColor: Colors.grey[900],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00FF41))),
          ),
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('Abrir Ajustes'),
          )
        ],
      ),
    );
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
      if (_isTracking) {
        _startNewTrip();
      } else {
        _stopTrip();
      }
    });
  }

  void _startNewTrip() {
    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _maxSpeed = 0.0;
    _avgSpeed = 0.0;
    _elevationGain = 0.0;
    _elevationLoss = 0.0;
    _totalSeconds = 0;
    _movingSeconds = 0;
    _consecutiveZeroSpeedTicks = 0;
    _isAutoPaused = false;
    _lastAltitude = null;
    _routePoints.clear();
    _lastLatitude = null;
    _lastLongitude = null;

    // Cronómetro de segundo a segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _totalSeconds++;
        if (!_isAutoPaused) {
          _movingSeconds++;
          if (_movingSeconds > 2 && _totalDistance > 0.01) {
            _avgSpeed = _totalDistance / (_movingSeconds / 3600);
          }
        }
      });
    });

    if (_gpsServiceInitialized && _rawGpsService != null) {
      try {
        _gpsStream = _rawGpsService!.locationStream.listen(
          (gpsData) {
            _updateLocationFromRawGps(gpsData);
          },
          onError: (e) {
            _showSnack("⚠️ Error de GPS: $e");
          },
        );
      } catch (e) {
        _showSnack("⚠️ No se pudo iniciar el sensor GPS");
      }
    } else {
      _showSnack("⚠️ Sensor GPS no disponible");
    }
  }

  void _updateLocationFromRawGps(RawGpsData gpsData) {
    if (!mounted) return;

    setState(() {
      _currentSpeed = gpsData.speedKmh;

      // Auto-pausa ciclista: umbral de 1.8 km/h para distinguir pedaleo lento de paradas
      if (_currentSpeed < 1.8) {
        _consecutiveZeroSpeedTicks++;
        if (_consecutiveZeroSpeedTicks >= 3) {
          _isAutoPaused = true;
          _currentSpeed = 0.0;
        }
      } else {
        _consecutiveZeroSpeedTicks = 0;
        _isAutoPaused = false;
      }

      // Actualizar velocidad punta
      if (_currentSpeed > _maxSpeed) {
        _maxSpeed = _currentSpeed;
      }

      // Acumular distancia solo si nos estamos moviendo (filtro de ruido en parado)
      if (!_isAutoPaused && _lastLatitude != null && _lastLongitude != null) {
        double distanceMeters = Geolocator.distanceBetween(
          _lastLatitude!,
          _lastLongitude!,
          gpsData.latitude,
          gpsData.longitude,
        );

        // Filtrar saltos irreales de GPS (> 50 m en 1 segundo en bici = 180 km/h)
        if (distanceMeters > 0.5 && distanceMeters < 50.0) {
          _totalDistance += distanceMeters / 1000.0;
        }
      }

      // Cálculo de altimetría y desnivel acumulado (+D / -D) con filtro de histéresis
      if (gpsData.altitude != 0.0) {
        if (_lastAltitude != null) {
          double altDiff = gpsData.altitude - _lastAltitude!;
          // Umbral de 1.2 metros para ignorar ruido barométrico/GPS
          if (altDiff > 1.2) {
            _elevationGain += altDiff;
            _lastAltitude = gpsData.altitude;
          } else if (altDiff < -1.2) {
            _elevationLoss += altDiff.abs();
            _lastAltitude = gpsData.altitude;
          }
        } else {
          _lastAltitude = gpsData.altitude;
        }
      }

      _lastLatitude = gpsData.latitude;
      _lastLongitude = gpsData.longitude;
      _satelliteCount = gpsData.satelliteCount;

      // Guardar punto de ruta
      _routePoints.add(TripPoint(
        latitude: gpsData.latitude,
        longitude: gpsData.longitude,
        altitude: gpsData.altitude,
        speedKmh: gpsData.speedKmh,
        timestamp: DateTime.now(),
      ));
    });

    // Actualizar clima solo periódicamente
    _fetchWeather(gpsData.latitude, gpsData.longitude);
  }

  void _stopTrip() async {
    _timer?.cancel();
    _gpsStream?.cancel();
    _currentSpeed = 0.0;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastAltitude = null;
    _isAutoPaused = false;

    // Guardar en la Base de Datos Local SQLite
    try {
      if (_totalDistance > 0.02) {
        final trip = Trip(
          fechaRegistro: _startTime ?? DateTime.now(),
          distanciaKm: _totalDistance,
          velocidadMaxKmh: _maxSpeed,
          velocidadMediaKmh: _avgSpeed,
          tiempoTotalSeg: _totalSeconds,
          tiempoMovimientoSeg: _movingSeconds > 0 ? _movingSeconds : _totalSeconds,
          desnivelPositivoM: _elevationGain,
          desnivelNegativoM: _elevationLoss,
          rutaCoordenadas: List.from(_routePoints),
        );

        await DatabaseHelper.instance.insertTrip(trip);
        _showSnack("✅ Salida guardada en la base de datos local");
      } else {
        _showSnack("Trayecto demasiado corto, no se ha guardado.");
      }
    } catch (e) {
      _showSnack("❌ Error al guardar localmente: $e");
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    if (_lastWeatherUpdate != null &&
        DateTime.now().difference(_lastWeatherUpdate!).inMinutes < 15) {
      return;
    }

    final data = await _weatherService.getWeather(lat, lon);
    if (mounted && data.isNotEmpty) {
      setState(() {
        _currentTemp = data['temperature'];
        _weatherCode = data['weathercode'];
        _windSpeed = data['windspeed'];
        final double windDir = data['winddirection'] ?? 0.0;
        _windDirection = _weatherService.getWindCardinal(windDir);
        _weatherError = false;
        _lastWeatherUpdate = DateTime.now();
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.grey[900],
      duration: const Duration(seconds: 2),
    ));
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  /// Diseño Vertical para soporte de manillar estándar
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildHeader(),
        if (_isTracking && _isAutoPaused) _buildAutoPauseBanner(),
        const Spacer(),
        _buildSpeedometerDisplay(),
        const Spacer(),
        _buildCyclingStatsCard(),
        _buildActionButton(),
      ],
    );
  }

  /// Diseño Horizontal para soporte de manillar apaisado
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Lado izquierdo: Velocímetro gigante
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildHeader(),
              if (_isTracking && _isAutoPaused) _buildAutoPauseBanner(),
              const Spacer(),
              _buildSpeedometerDisplay(),
              const Spacer(),
            ],
          ),
        ),
        // Lado derecho: Métricas ciclistas y botón
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(child: Center(child: _buildCyclingStatsCard())),
              _buildActionButton(),
            ],
          ),
        ),
      ],
    );
  }

  /// Cabecera superior con reloj, satélites y clima ciclista (temp + viento)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Historial y Satélites
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white70, size: 28),
                onPressed: _navigateToHistory,
                tooltip: 'Historial de Rutas',
              ),
              if (_isTracking)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _satelliteCount >= 4
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.satellite_alt,
                        size: 14,
                        color: _satelliteCount >= 4 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_satelliteCount',
                        style: TextStyle(
                          color: _satelliteCount >= 4 ? Colors.green : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Clima ciclista y Hora
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildWeatherInfo(),
              StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  final now = tz.TZDateTime.now(tz.local);
                  return Text(
                    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Banner indicador de Pausa Automática
  Widget _buildAutoPauseBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.6)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_filled, color: Colors.amberAccent, size: 16),
          SizedBox(width: 6),
          Text(
            'AUTO-PAUSA (DETENIDO)',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Pantalla central con la velocidad actual en números grandes para visibilidad solar
  Widget _buildSpeedometerDisplay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentSpeed.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 140,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00FF41),
            letterSpacing: -5,
            height: 1.0,
          ),
        ),
        const Text(
          "KM/H",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white38,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Cuadrícula con las 4 métricas ciclistas vitales
  Widget _buildCyclingStatsCard() {
    final movingDuration = Duration(seconds: _movingSeconds);
    final formattedTime =
        "${movingDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${movingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat("DISTANCIA", "${_totalDistance.toStringAsFixed(2)} km"),
          _buildStat("TIEMPO", formattedTime),
          _buildStat("MEDIA", "${_avgSpeed.toStringAsFixed(1)} km/h"),
          _buildStat("DESNIVEL", "+${_elevationGain.toStringAsFixed(0)} m"),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Botón ergonómico de gran tamaño apto para guantes de ciclista
  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _toggleTracking,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isTracking ? Colors.redAccent : const Color(0xFF00FF41),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.stop_circle : Icons.pedal_bike,
              size: 26,
              color: Colors.black,
            ),
            const SizedBox(width: 10),
            Text(
              _isTracking ? "DETENER TRAYECTO" : "INICIAR speeDGA",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Información meteorológica adaptada a ciclistas (temperatura y viento)
  Widget _buildWeatherInfo() {
    if (_weatherError) {
      return const SizedBox.shrink();
    }
    if (_currentTemp == null) {
      return const Text("Cargando clima...", style: TextStyle(color: Colors.white30, fontSize: 11));
    }

    final weatherIcon = _weatherService.getWeatherIcon(_weatherCode ?? 0);
    final windInfo = _windSpeed != null && _windDirection != null
        ? " 💨 ${_windSpeed!.toStringAsFixed(0)} km/h $_windDirection"
        : "";

    return Row(
      children: [
        Text(weatherIcon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          "${_currentTemp!.toStringAsFixed(0)}°C$windInfo",
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsStream?.cancel();
    _rawGpsService?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}
