import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'garage_screen.dart';
import 'history_screen.dart';
import 'models/bike.dart';
import 'models/trip.dart';
import 'raw_gps_service.dart';
import 'services/bike_service.dart';
import 'services/database_helper.dart';
import 'services/settings_service.dart';
import 'settings_screen.dart';
import 'theme/speedga_theme.dart';
import 'weather_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar almacenamiento local (SQLite en móvil, localStorage en Web)
  try {
    await DatabaseHelper.instance.init();
  } catch (e) {
    debugPrint('⚠️ Error inicializando DatabaseHelper: $e');
  }

  // Inicializar servicio de garaje y bicicletas
  try {
    await BikeService.instance.init();
  } catch (e) {
    debugPrint('⚠️ Error inicializando BikeService: $e');
  }

  // Inicializar servicio de ajustes
  try {
    await SettingsService.instance.init();
  } catch (e) {
    debugPrint('⚠️ Error inicializando SettingsService: $e');
  }

  runApp(const SpeeDGAApp());
}

class SpeeDGAApp extends StatelessWidget {
  const SpeeDGAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'speeDGA - Ciclocomputador Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SpeeDGATheme.oledBlack,
        colorScheme: const ColorScheme.dark(
          primary: SpeeDGATheme.neonLime,
          surface: SpeeDGATheme.darkCard,
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

/// Contenedor de navegación principal (Opción 2 - Barra flotante con botón central elevado)
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final GlobalKey<_SpeedometerPageState> _speedometerKey = GlobalKey<_SpeedometerPageState>();
  final ValueNotifier<bool> _isTrackingNotifier = ValueNotifier<bool>(false);

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpeeDGATheme.oledBlack,
      // Usar IndexedStack para mantener SpeedometerPage siempre viva y activa en memoria
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SpeedometerPage(
            key: _speedometerKey,
            trackingNotifier: _isTrackingNotifier,
            onNavigateToHistory: () => _onTabSelected(1),
            onNavigateToGarage: () => _onTabSelected(2),
          ),
          const HistoryScreen(showBackButton: false),
          const GarageScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF070A0D),
        border: Border(
          top: BorderSide(color: SpeeDGATheme.darkBorder, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.speed, 'Grabar'),
              _buildNavItem(1, Icons.show_chart, 'Salidas'),
              _buildCenterActionButton(),
              _buildNavItem(2, Icons.pedal_bike, 'Bicis'),
              _buildNavItem(3, Icons.person_outline, 'Perfil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? SpeeDGATheme.neonLime : SpeeDGATheme.textSecondary;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón central elevado con indicador de estado (Opción 2)
  Widget _buildCenterActionButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTrackingNotifier,
      builder: (context, isTracking, child) {
        return GestureDetector(
          onTap: () {
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
            _speedometerKey.currentState?.toggleTracking();
          },
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isTracking ? SpeeDGATheme.pulseRed : SpeeDGATheme.neonLime,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: SpeeDGATheme.neonGlow(
                      color: isTracking ? SpeeDGATheme.pulseRed : SpeeDGATheme.neonLime,
                      blur: 22,
                      spread: 2,
                    ),
                  ),
                  child: Icon(
                    isTracking ? Icons.stop : Icons.add,
                    color: isTracking ? Colors.white : Colors.black,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isTracking ? 'DETENER' : 'INICIAR',
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isTracking ? SpeeDGATheme.pulseRed : SpeeDGATheme.neonLime,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SpeedometerPage extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  final VoidCallback? onNavigateToGarage;
  final ValueNotifier<bool>? trackingNotifier;

  const SpeedometerPage({
    super.key,
    this.onNavigateToHistory,
    this.onNavigateToGarage,
    this.trackingNotifier,
  });

  @override
  State<SpeedometerPage> createState() => _SpeedometerPageState();
}

class _SpeedometerPageState extends State<SpeedometerPage> {
  // --- Métricas de Telemetría Ciclista (Exactas y Preservadas) ---
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _avgSpeed = 0.0;
  double _totalDistance = 0.0;
  double _elevationGain = 0.0;
  double _elevationLoss = 0.0;
  double? _lastAltitude;

  bool _isTracking = false;
  bool _isAutoPaused = false;
  bool _screenLockEnabled = true;
  int _savedTripsCount = 14;

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
    _startGpsStream();
    try {
      await WakelockPlus.enable();
    } catch (_) {}
    _loadInitialWeather();
    _loadTripCount();
  }

  void _loadTripCount() async {
    try {
      final trips = await DatabaseHelper.instance.getTrips();
      if (mounted && trips.isNotEmpty) {
        setState(() {
          _savedTripsCount = trips.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInitialWeather() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
      }
      if (position != null) {
        await _fetchWeather(position.latitude, position.longitude);
      }
    } catch (_) {
      // Si la señal o permisos aún no están concedidos, se reintentará en el stream GPS
    }
  }

  Future<void> _checkPermissions() async {
    if (kIsWeb) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('⚠️ Permiso de ubicación bloqueado en el navegador');
      }
      return;
    }

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
        backgroundColor: SpeeDGATheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SpeeDGATheme.darkBorder),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: SpeeDGATheme.neonLime)),
          ),
          TextButton(
            onPressed: () => Geolocator.openAppSettings(),
            child: const Text('Abrir Ajustes'),
          )
        ],
      ),
    );
  }

  /// Método público para alternar la grabación
  void toggleTracking() => _toggleTracking();

  void _toggleTracking() async {
    if (!_isTracking) {
      if (kIsWeb) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          _showSnack("⚠️ Concede permiso de ubicación en el navegador para usar el velocímetro");
          return;
        }
      }
      setState(() {
        _isTracking = true;
      });
      widget.trackingNotifier?.value = true;
      _startNewTrip();
    } else {
      setState(() {
        _isTracking = false;
      });
      widget.trackingNotifier?.value = false;
      _stopTrip();
    }
  }

  void _startGpsStream() {
    if (_gpsStream != null) return;
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
        _showSnack("⚠️ No se pudo iniciar el sensor GPS: $e");
      }
    } else {
      _showSnack("⚠️ Sensor GPS no disponible");
    }
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
    _isAutoPaused = false;
    _lastAltitude = null;
    _routePoints.clear();
    _lastLatitude = null;
    _lastLongitude = null;

    _startGpsStream();

    // Cronómetro de segundo a segundo (exacto)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _totalSeconds++;
        if (_currentSpeed >= 1.0) {
          _movingSeconds++;
          if (_movingSeconds > 2 && _totalDistance > 0.01) {
            _avgSpeed = _totalDistance / (_movingSeconds / 3600.0);
          }
        }
      });
    });
  }

  void _updateLocationFromRawGps(RawGpsData gpsData) {
    if (!mounted) return;

    setState(() {
      // 1. Velocidad directa del sensor GPS (con filtro de reposo estándar < 0.8 km/h preservado)
      double speed = gpsData.speedKmh;
      if (speed < 0.8) {
        speed = 0.0;
      }

      _currentSpeed = speed;
      _satelliteCount = gpsData.satelliteCount;

      // 2. Si estamos grabando una salida en curso, calcular métricas de ruta
      if (_isTracking) {
        // Indicador de auto-pausa (solo para visualización y temporizador de pedaleo)
        _isAutoPaused = (_currentSpeed < 1.0);

        // Actualizar velocidad máxima registrada
        if (_currentSpeed > _maxSpeed) {
          _maxSpeed = _currentSpeed;
        }

        // Acumular distancia real recorrida
        if (_lastLatitude != null && _lastLongitude != null) {
          double distanceMeters = Geolocator.distanceBetween(
            _lastLatitude!,
            _lastLongitude!,
            gpsData.latitude,
            gpsData.longitude,
          );

          // Filtro para eliminar micropasos en parado (< 0.6 m) y saltos cuánticos (> 100 m/s)
          if (distanceMeters > 0.6 && distanceMeters < 100.0) {
            _totalDistance += distanceMeters / 1000.0;
          }
        }

        // Cálculo de altimetría y desnivel acumulado (+D / -D) con histéresis (preservado)
        if (gpsData.altitude != 0.0) {
          if (_lastAltitude != null) {
            double altDiff = gpsData.altitude - _lastAltitude!;
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

        // Guardar punto de ruta para trazado GPX y visor de mapa
        _routePoints.add(TripPoint(
          latitude: gpsData.latitude,
          longitude: gpsData.longitude,
          altitude: gpsData.altitude,
          speedKmh: _currentSpeed,
          timestamp: DateTime.now(),
        ));
      }

      _lastLatitude = gpsData.latitude;
      _lastLongitude = gpsData.longitude;
    });

    // Actualizar clima periódicamente
    _fetchWeather(gpsData.latitude, gpsData.longitude);
  }

  void _stopTrip() async {
    _timer?.cancel();
    _isAutoPaused = false;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastAltitude = null;

    // Guardar en la Base de Datos Local (SQLite en móvil, localStorage en Web)
    try {
      if (_totalDistance > 0.01) {
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

        // Actualizar odómetro y telemetría de la bicicleta activa en el Garaje
        try {
          await BikeService.instance.recordTripForActiveBike(
            distanceKm: _totalDistance,
            elevationM: _elevationGain,
          );
        } catch (_) {}

        _loadTripCount();
        _showSnack("✅ Salida guardada correctamente");
      } else {
        _showSnack("Trayecto demasiado corto, no se ha guardado.");
      }
    } catch (e) {
      _showSnack("❌ Error al guardar: $e");
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
        _lastWeatherUpdate = DateTime.now();
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: SpeeDGATheme.darkCard,
      duration: const Duration(seconds: 2),
    ));
  }

  String _getZoneName(double speed) {
    if (speed < 0.8) return 'DETENIDO';
    if (speed < 18.0) return 'ZONA RECUPERACIÓN';
    if (speed < 30.0) return 'ZONA RESISTENCIA';
    if (speed < 42.0) return 'ZONA RITMO / TEMPO';
    if (speed < 50.0) return 'ZONA UMBRAL';
    return 'ZONA ANAERÓBICA';
  }

  Color _getZoneColor(double speed) {
    if (speed < 0.8) return SpeeDGATheme.textMuted;
    if (speed < 18.0) return SpeeDGATheme.aeroCyan;
    if (speed < 30.0) return SpeeDGATheme.neonLime;
    if (speed < 42.0) return SpeeDGATheme.electricCyan;
    if (speed < 50.0) return SpeeDGATheme.warningAmber;
    return SpeeDGATheme.pulseRed;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: SpeeDGATheme.oledBlack,
      body: SafeArea(
        child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
      ),
    );
  }

  /// Opción 2 - Diseño Vertical: Velocímetro Gigante + 4 Cápsulas Bento
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        _buildStitchHeader(),
        if (_isTracking && _isAutoPaused) _buildAutoPauseBanner(),
        Expanded(
          child: Center(
            child: _buildGiantSpeedometerDisplay(),
          ),
        ),
        _buildSecondaryMetricsGrid(),
        _buildUtilityBar(),
        const SizedBox(height: 6),
      ],
    );
  }

  /// Diseño Horizontal para soporte de manillar apaisado
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildStitchHeader(),
              if (_isTracking && _isAutoPaused) _buildAutoPauseBanner(),
              Expanded(
                child: Center(
                  child: _buildGiantSpeedometerDisplay(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildSecondaryMetricsGrid(),
                _buildUtilityBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Cabecera superior (Opción 2): GPS Lock + Batería + Bici Activa + Contador Historial
  Widget _buildStitchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Column(
        children: [
          // Fila 1: Píldoras GPS Lock, Batería, Bici Carretera y Botón Historial con Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // GPS Lock pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SpeeDGATheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SpeeDGATheme.darkBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _satelliteCount >= 3 ? SpeeDGATheme.neonLime : SpeeDGATheme.warningAmber,
                            shape: BoxShape.circle,
                            boxShadow: SpeeDGATheme.neonGlow(
                              color: _satelliteCount >= 3 ? SpeeDGATheme.neonLime : SpeeDGATheme.warningAmber,
                              blur: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _satelliteCount >= 3 ? 'GPS LOCK' : 'GPS BUSCANDO',
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Battery pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: SpeeDGATheme.darkCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: SpeeDGATheme.darkBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, size: 13, color: SpeeDGATheme.textSecondary),
                        SizedBox(width: 3),
                        Text(
                          '88%',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: SpeeDGATheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Chip Bici Activa
                  ValueListenableBuilder<Bike?>(
                    valueListenable: BikeService.instance.activeBikeNotifier,
                    builder: (context, bike, child) {
                      final hasBike = bike != null;
                      final bikeName = hasBike ? bike.name : 'Añadir Bici';
                      return GestureDetector(
                        onTap: widget.onNavigateToGarage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: SpeeDGATheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasBike
                                  ? SpeeDGATheme.neonLime.withOpacity(0.35)
                                  : SpeeDGATheme.alertOrange.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasBike ? Icons.pedal_bike : Icons.add_circle_outline,
                                size: 13,
                                color: hasBike ? SpeeDGATheme.neonLime : SpeeDGATheme.alertOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bikeName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: hasBike ? Colors.white : SpeeDGATheme.alertOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // Botón de Historial con Badge de número de rutas
              GestureDetector(
                onTap: widget.onNavigateToHistory,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpeeDGATheme.darkBorder),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.history, color: Colors.white, size: 18),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: SpeeDGATheme.neonLime,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: SpeeDGATheme.neonGlow(blur: 6),
                          ),
                          child: Text(
                            '$_savedTripsCount',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila 2: Chips de Clima, Viento y Reloj local
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpeeDGATheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _weatherService.getWeatherIcon(_weatherCode ?? 0),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentTemp != null ? "${_currentTemp!.toStringAsFixed(0)}°C" : "21°C Despejado",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpeeDGATheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.air, size: 13, color: SpeeDGATheme.aeroCyan),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _windSpeed != null && _windDirection != null
                              ? "${_windSpeed!.toStringAsFixed(0)} km/h $_windDirection"
                              : "8 km/h NE",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: SpeeDGATheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpeeDGATheme.darkBorder),
                ),
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    return Text(
                      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SpeeDGATheme.textSecondary,
                      ),
                    );
                  },
                ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: SpeeDGATheme.warningAmber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SpeeDGATheme.warningAmber.withOpacity(0.6)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause_circle_filled, color: SpeeDGATheme.warningAmber, size: 16),
          SizedBox(width: 6),
          Text(
            'AUTO-PAUSA (DETENIDO)',
            style: TextStyle(
              color: SpeeDGATheme.warningAmber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Central de la Opción 2: Velocímetro Gigante sin dial exterior
  Widget _buildGiantSpeedometerDisplay() {
    final double safeSpeed = _currentSpeed.clamp(0.0, 120.0);
    final String zoneName = _getZoneName(safeSpeed);
    final Color zoneColor = _getZoneColor(safeSpeed);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Badge de Zona de Rendimiento
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: SpeeDGATheme.darkCard.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: zoneColor.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: zoneColor,
                      shape: BoxShape.circle,
                      boxShadow: SpeeDGATheme.neonGlow(color: zoneColor, blur: 8),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    zoneName,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: zoneColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Dígitos gigantes de velocidad (Opción 2: 124px - 140px con resplandor neón)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                safeSpeed.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 130,
                  fontWeight: FontWeight.w900,
                  color: SpeeDGATheme.neonLime,
                  letterSpacing: -4.0,
                  height: 0.92,
                  shadows: [
                    Shadow(
                      color: SpeeDGATheme.neonLime.withOpacity(0.75),
                      blurRadius: 28,
                    ),
                    Shadow(
                      color: SpeeDGATheme.neonLime.withOpacity(0.35),
                      blurRadius: 55,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 3. Unidades KM / H con chip GPS
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "KM / H",
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: SpeeDGATheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.darkCardElevated,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: SpeeDGATheme.darkBorder),
                  ),
                  child: const Text(
                    "GPS",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SpeeDGATheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Cápsula MÁX & Ritmo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF090D11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SpeeDGATheme.darkBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "MÁX: ",
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: SpeeDGATheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "${_maxSpeed.toStringAsFixed(1)} km/h",
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "  |  ",
                    style: TextStyle(color: SpeeDGATheme.darkBorder),
                  ),
                  Text(
                    _isTracking && _avgSpeed > 0
                        ? "+${(_currentSpeed - _avgSpeed).toStringAsFixed(1)} km/h ritmo"
                        : "+3.0 km/h ritmo",
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: SpeeDGATheme.neonLime,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cuadrícula Bento de 4 métricas secundarias limpias (Opción 2)
  Widget _buildSecondaryMetricsGrid() {
    final movingDuration = Duration(seconds: _movingSeconds);
    final formattedTime =
        "${movingDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${movingDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.15,
        children: [
          // Tarjeta 1: DISTANCIA
          _buildBentoMetricCard(
            label: 'DISTANCIA',
            value: _totalDistance.toStringAsFixed(2),
            unit: 'km',
            icon: Icons.straighten,
            iconColor: SpeeDGATheme.neonLime,
          ),
          // Tarjeta 2: TIEMPO ACTIVO
          _buildBentoMetricCard(
            label: 'TIEMPO ACTIVO',
            value: formattedTime,
            unit: 'min',
            icon: Icons.timer_outlined,
            iconColor: SpeeDGATheme.neonLime,
          ),
          // Tarjeta 3: VEL. MEDIA
          _buildBentoMetricCard(
            label: 'VEL. MEDIA',
            value: _avgSpeed.toStringAsFixed(1),
            unit: 'km/h',
            icon: Icons.show_chart,
            iconColor: SpeeDGATheme.aeroCyan,
          ),
          // Tarjeta 4: DESNIVEL +
          _buildBentoMetricCard(
            label: 'DESNIVEL +',
            value: '+${_elevationGain.toStringAsFixed(0)}',
            unit: 'm',
            icon: Icons.terrain,
            iconColor: SpeeDGATheme.warningAmber,
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: SpeeDGATheme.bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: SpeeDGATheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: SpeeDGATheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Barra de utilidades: estado de auto-pausa y toggle de bloqueo de pantalla
  Widget _buildUtilityBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SpeeDGATheme.neonLime,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Auto-pausa activada',
                style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              setState(() {
                _screenLockEnabled = !_screenLockEnabled;
              });
              try {
                if (_screenLockEnabled) {
                  await WakelockPlus.enable();
                } else {
                  await WakelockPlus.disable();
                }
              } catch (_) {}
            },
            child: Row(
              children: [
                Icon(
                  _screenLockEnabled ? Icons.lock_outline : Icons.lock_open,
                  size: 13,
                  color: _screenLockEnabled ? SpeeDGATheme.neonLime : SpeeDGATheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  _screenLockEnabled ? 'Always-On Activo' : 'Bloqueo estándar',
                  style: TextStyle(
                    fontSize: 11,
                    color: _screenLockEnabled ? SpeeDGATheme.neonLime : SpeeDGATheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsStream?.cancel();
    _rawGpsService?.dispose();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }
}
