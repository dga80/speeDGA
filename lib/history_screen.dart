import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/database_helper.dart';
import '../services/gpx_service.dart';
import 'map_screen.dart';

/// Pantalla de Historial de Salidas en Bicicleta con base de datos local SQLite y exportación GPX
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Trip>> _futureTrips;
  late Future<Map<String, dynamic>> _futureStats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _futureTrips = DatabaseHelper.instance.getTrips();
      _futureStats = DatabaseHelper.instance.getGlobalStats();
    });
  }

  void _deleteTrip(int id) async {
    try {
      await DatabaseHelper.instance.deleteTrip(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salida eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportGpx(Trip trip) async {
    try {
      await GpxService.shareTripGpx(trip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar GPX: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _navigateToMap(Trip trip) {
    if (trip.rutaCoordenadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta salida no contiene coordenadas de ruta.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final coordsList = trip.rutaCoordenadas
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          routeCoordinates: coordsList,
          trip: trip,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mis Salidas en Bici'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          children: [
            // Cabecera: Resumen Global del Ciclista (Odómetro y Desnivel de por vida)
            FutureBuilder<Map<String, dynamic>>(
              future: _futureStats,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final stats = snapshot.data!;
                return _buildLifetimeStatsCard(stats);
              },
            ),
            const SizedBox(height: 16),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'HISTORIAL DE RUTAS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Lista de Salidas
            FutureBuilder<List<Trip>>(
              future: _futureTrips,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF00FF41)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error al cargar el historial: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }
                final trips = snapshot.data ?? [];
                if (trips.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(trip);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de Estadísticas Acumuladas
  Widget _buildLifetimeStatsCard(Map<String, dynamic> stats) {
    final double totalKm = stats['totalKm'] ?? 0.0;
    final double totalDesnivel = stats['totalDesnivel'] ?? 0.0;
    final int totalSalidas = stats['totalSalidas'] ?? 0;
    final double maxVel = stats['maxVelocidad'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, const Color(0xFF162519)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pedal_bike, color: Color(0xFF00FF41), size: 22),
              SizedBox(width: 8),
              Text(
                'ODÓMETRO TOTAL DE LA BICI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatBadge('${totalKm.toStringAsFixed(1)} km', 'DISTANCIA'),
              _buildStatBadge('+${totalDesnivel.toStringAsFixed(0)} m', 'DESNIVEL'),
              _buildStatBadge('$totalSalidas', 'SALIDAS'),
              _buildStatBadge('${maxVel.toStringAsFixed(1)} km/h', 'MÁXIMA'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FF41),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Tarjeta de una Salida Individual
  Widget _buildTripCard(Trip trip) {
    final localTime = trip.fechaRegistro.toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(localTime);

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Fecha y botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Botón Exportar GPX (Strava)
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.amberAccent, size: 20),
                      onPressed: () => _exportGpx(trip),
                      tooltip: 'Exportar GPX (Strava)',
                      visualDensity: VisualDensity.compact,
                    ),
                    // Botón Ver Mapa
                    IconButton(
                      icon: const Icon(Icons.map_outlined, color: Colors.lightBlueAccent, size: 22),
                      onPressed: () => _navigateToMap(trip),
                      tooltip: 'Ver Mapa',
                      visualDensity: VisualDensity.compact,
                    ),
                    // Botón Eliminar
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _showDeleteConfirmation(trip.id!),
                      tooltip: 'Eliminar',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),

            // Métricas principales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTripMetric(
                  icon: Icons.straighten,
                  value: '${trip.distanciaKm.toStringAsFixed(2)} km',
                  label: 'Distancia',
                ),
                _buildTripMetric(
                  icon: Icons.speed,
                  value: '${trip.velocidadMediaKmh.toStringAsFixed(1)} km/h',
                  label: 'Vel. Media',
                ),
                _buildTripMetric(
                  icon: Icons.terrain,
                  value: '+${trip.desnivelPositivoM.toStringAsFixed(0)} m',
                  label: 'Desnivel +',
                ),
                _buildTripMetric(
                  icon: Icons.timer_outlined,
                  value: trip.formattedMovingTime,
                  label: 'Tiempo',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripMetric({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00FF41)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.directions_bike, size: 70, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes salidas guardadas',
              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia una ruta en el velocímetro para empezar a registrar.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Confirmar borrado', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¿Estás seguro de que quieres borrar esta salida? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Borrar'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTrip(id);
              },
            ),
          ],
        );
      },
    );
  }
}
