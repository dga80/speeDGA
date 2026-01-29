import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'history_screen.dart'; // Importar la nueva pantalla

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://npoekhbuijevesjjbbyx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wb2VraGJ1aWpldmVzampiYnl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0MjMwMjcsImV4cCI6MjA4Mjk5OTAyN30.ZEmWiOdyHrIsv4pPP7eYSdzP2lNAEmpwCPdOPeWnzjU',
  );

  runApp(const SpeeDGAApp());
}

class SpeeDGAApp extends StatelessWidget {
  const SpeeDGAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'speeDGA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
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
  // --- Variables de Estado ---
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  bool _isTracking = false;
  
  DateTime? _startTime;
  Duration _duration = Duration.zero;
  Timer? _timer;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  final List<Map<String, double>> _routePoints = []; // Lista para guardar la ruta

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    await _checkPermissions();
    WakelockPlus.enable();
  }

  Future<void> _checkPermissions() async {
    // 1. Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog(
        '📍 Ubicación Desactivada',
        'Los servicios de ubicación están desactivados en tu dispositivo. Por favor, actívalos para usar speeDGA.',
      );
      return;
    }

    // 2. Solicitar permiso de ubicación usando permission_handler
    PermissionStatus status = await Permission.location.status;
    
    if (status.isDenied) {
      // Solicitar permiso por primera vez
      status = await Permission.location.request();
    }
    
    if (status.isDenied) {
      // El usuario denegó el permiso
      _showDialog(
        '⚠️ Permiso Denegado',
        'speeDGA necesita acceso a tu ubicación para funcionar. Por favor, concede el permiso cuando se te solicite.',
      );
      return;
    }
    
    if (status.isPermanentlyDenied) {
      // El usuario denegó permanentemente el permiso
      _showDialog(
        '🔒 Permiso Bloqueado',
        'Los permisos de ubicación están bloqueados permanentemente. Por favor, ve a los ajustes de Android y activa manualmente el permiso de ubicación para speeDGA.',
      );
      return;
    }
    
    // 3. Verificar también con Geolocator (doble verificación)
    LocationPermission geoPermission = await Geolocator.checkPermission();
    if (geoPermission == LocationPermission.denied) {
      geoPermission = await Geolocator.requestPermission();
    }
    
    if (geoPermission == LocationPermission.deniedForever) {
      _showDialog(
        '🔒 Permiso Bloqueado',
        'Los permisos de ubicación están bloqueados. Abre los ajustes de Android y activa el permiso de ubicación para speeDGA.',
      );
      return;
    }
    
    // Si llegamos aquí, todo está bien
    if (status.isGranted && geoPermission != LocationPermission.denied) {
      _showSnack('✅ Permisos de ubicación concedidos correctamente');
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content),
        backgroundColor: Colors.grey[900],
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
    _duration = Duration.zero;
    _routePoints.clear(); // Limpiar la ruta anterior
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(_startTime!);
      });
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Actualiza cada 5 metros para no saturar
      ),
    ).listen(
      _updateLocation,
      onError: (e) {
        _showSnack("⚠️ Error de ubicación: $e");
      },
    );
  }

  void _updateLocation(Position position) {
    setState(() {
      _currentSpeed = position.speed * 3.6;
      if (_currentSpeed < 1.0) _currentSpeed = 0.0;
      if (_currentSpeed > _maxSpeed) _maxSpeed = _currentSpeed;

      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude
        );
        _totalDistance += distance / 1000;
      }
      _lastPosition = position;
      _routePoints.add({'lat': position.latitude, 'lng': position.longitude});
    });
  }

  void _stopTrip() async {
    _timer?.cancel();
    _positionStream?.cancel();
    _currentSpeed = 0.0;
    _lastPosition = null;

    // Guardar en Supabase
    try {
      if (_totalDistance > 0.01) { // Solo guardar si hay movimiento
        await Supabase.instance.client.from('registros_velocidad').insert({
          'fecha_registro': DateTime.now().toIso8601String(),
          'distancia_recorrida_km': _totalDistance,
          'velocidad_maxima_kmh': _maxSpeed,
          'tiempo_total_segundos': _duration.inSeconds,
          'ruta_coordenadas': _routePoints // Guardar la ruta
        });
        _showSnack("Trayecto guardado en speeDGA");
      } else {
        _showSnack("Trayecto demasiado corto, no se ha guardado.");
      }
    } catch (e) {
      _showSnack("Error al guardar: ${e.toString()}");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  
  void _navigateToHistory() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Superior: Hora y Botón de Historial
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de Historial
                  IconButton(
                      icon: const Icon(Icons.history, color: Colors.white70, size: 30),
                      onPressed: _navigateToHistory, 
                      tooltip: 'Historial de Trayectos'
                  ),
                  // Hora Actual
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final now = DateTime.now();
                      return Text(
                        "${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}",
                        style: const TextStyle(fontSize: 22, color: Colors.white70, fontWeight: FontWeight.w300),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const Spacer(),

            // Velocímetro
            Text(
              _currentSpeed.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 180, fontWeight: FontWeight.w900,
                color: Color(0xFF00FF41), letterSpacing: -5,
              ),
            ),
            const Text("KM/H", style: TextStyle(fontSize: 24, color: Colors.white38, letterSpacing: 4)),

            const Spacer(),

            // Estadísticas
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("DISTANCIA", "${_totalDistance.toStringAsFixed(2)} km"),
                  _buildStat("TIEMPO", _formatDuration(_duration)),
                  _buildStat("MÁXIMA", _maxSpeed.toStringAsFixed(1)),
                ],
              ),
            ),

            // Botón de Acción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _toggleTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.redAccent : const Color(0xFF00FF41),
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  _isTracking ? "DETENER TRAYECTO" : "INICIAR speeDGA",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }
}
