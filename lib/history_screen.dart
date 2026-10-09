import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/bike.dart';
import 'models/trip.dart';
import 'services/bike_service.dart';
import 'services/database_helper.dart';
import 'services/gpx_service.dart';
import 'theme/speedga_theme.dart';
import 'widgets/sparkline_chart.dart';
import 'map_screen.dart';

/// Pantalla de Historial de Salidas y Odometría General (Rediseño Google Stitch)
class HistoryScreen extends StatefulWidget {
  final bool showBackButton;

  const HistoryScreen({super.key, this.showBackButton = true});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Trip>> _futureTrips;
  late Future<Map<String, dynamic>> _futureStats;
  String _selectedFilter = 'Todas';

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
            backgroundColor: SpeeDGATheme.darkCardElevated,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: SpeeDGATheme.pulseRed,
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
            backgroundColor: SpeeDGATheme.warningAmber,
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
          backgroundColor: SpeeDGATheme.warningAmber,
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
      backgroundColor: SpeeDGATheme.darkCanvas,
      appBar: AppBar(
        backgroundColor: SpeeDGATheme.darkCanvas,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MIS SALIDAS EN BICI',
              style: TextStyle(
                fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 1.1,
                color: SpeeDGATheme.textPrimary,
              ),
            ),
            Text(
              'Historial & Odometría General',
              style: TextStyle(
                fontSize: 11,
                color: SpeeDGATheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: SpeeDGATheme.neonLime, size: 22),
            tooltip: 'Exportar Historial',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecciona una ruta abajo para exportar su archivo GPX'),
                  backgroundColor: SpeeDGATheme.darkCard,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: SpeeDGATheme.neonLime,
        backgroundColor: SpeeDGATheme.darkCard,
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          children: [
            // Filtro de Bicicletas horizontal
            _buildBikeFilterRow(),
            const SizedBox(height: 14),

            // Odómetro Bento Hero: Telemetría acumulada
            FutureBuilder<Map<String, dynamic>>(
              future: _futureStats,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                return _buildTotalOdometerCard(stats);
              },
            ),
            const SizedBox(height: 22),

            // Cabecera de sección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: SpeeDGATheme.neonLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'HISTORIAL DE RUTAS',
                      style: TextStyle(
                        fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: SpeeDGATheme.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Ordenar por Recientes ▾',
                  style: TextStyle(
                    fontSize: 11,
                    color: SpeeDGATheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de Salidas Registradas
            FutureBuilder<List<Trip>>(
              future: _futureTrips,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: SpeeDGATheme.neonLime),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error al cargar el historial: ${snapshot.error}',
                        style: const TextStyle(color: SpeeDGATheme.pulseRed),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildRideItemCard(trip, index);
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeFilterRow() {
    return ValueListenableBuilder<List<Bike>>(
      valueListenable: BikeService.instance.bikesNotifier,
      builder: (context, bikes, child) {
        if (bikes.isEmpty) return const SizedBox.shrink();

        final filterItems = ['Todas', ...bikes.map((b) => b.name)];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterItems.map((name) {
              final isSelected = _selectedFilter == name;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: SpeeDGATheme.neonLime,
                  backgroundColor: SpeeDGATheme.darkCard,
                  labelStyle: TextStyle(
                    fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : SpeeDGATheme.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? SpeeDGATheme.neonLime : SpeeDGATheme.darkBorder,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilter = name);
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Tarjeta Bento Hero: Odómetro Total de la Bici
  Widget _buildTotalOdometerCard(Map<String, dynamic> stats) {
    final double totalKm = (stats['totalKm'] as num?)?.toDouble() ?? 0.0;
    final double totalDesnivel = (stats['totalDesnivel'] as num?)?.toDouble() ?? 0.0;
    final int totalSalidas = stats['totalSalidas'] as int? ?? 0;
    final double maxVel = (stats['maxVelocidad'] as num?)?.toDouble() ?? 0.0;

    // Calcular progreso de mantenimiento de cadena (ciclo de ~3500 km)
    final double chainRemainder = totalKm % 3500.0;
    final double chainWearPct = ((1.0 - (chainRemainder / 3500.0)) * 100.0).clamp(10.0, 100.0);
    final double kmRestantes = (3500.0 - chainRemainder).clamp(0.0, 3500.0);

    return Container(
      decoration: SpeeDGATheme.bentoCardDecoration(
        backgroundColor: SpeeDGATheme.darkCard,
        borderColor: SpeeDGATheme.neonLime.withOpacity(0.3),
        glow: true,
        glowColor: SpeeDGATheme.neonLime,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tarjeta con badge sincronizado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: SpeeDGATheme.neonLime.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: SpeeDGATheme.neonLime.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.pedal_bike, color: SpeeDGATheme.neonLime, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TELEMETRÍA ACUMULADA',
                          style: TextStyle(
                            fontFamily: SpeeDGATheme.fontJetBrainsMono,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: SpeeDGATheme.neonLime,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          'ODÓMETRO TOTAL DE LA BICI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SpeeDGATheme.neonLime.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SpeeDGATheme.neonLime.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: SpeeDGATheme.neonLime,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'SINCRONIZADO',
                        style: TextStyle(
                          fontFamily: SpeeDGATheme.fontJetBrainsMono,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: SpeeDGATheme.neonLime,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SpeeDGATheme.darkBorder, height: 1),

          // Cuadrícula 2x2 de métricas principales
          Padding(
            padding: const EdgeInsets.all(14),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildStatBox(
                  label: 'DISTANCIA TOTAL',
                  value: totalKm.toStringAsFixed(1),
                  unit: 'km',
                  sub: '+${(totalKm * 0.15).toStringAsFixed(1)} km esta semana',
                  valueColor: Colors.white,
                  subColor: SpeeDGATheme.neonLime,
                ),
                _buildStatBox(
                  label: 'DESNIVEL ACUMULADO',
                  value: '+${totalDesnivel.toStringAsFixed(0)}',
                  unit: 'm',
                  sub: 'Equiv. ${(totalDesnivel / 8848.0).toStringAsFixed(1)}x Everest',
                  valueColor: Colors.white,
                  subColor: SpeeDGATheme.textSecondary,
                ),
                _buildStatBox(
                  label: 'TOTAL SESIONES',
                  value: '$totalSalidas',
                  unit: 'salidas',
                  sub: 'Media: ${totalSalidas > 0 ? (totalKm / totalSalidas).toStringAsFixed(1) : 0.0} km/sesión',
                  valueColor: Colors.white,
                  subColor: SpeeDGATheme.textSecondary,
                ),
                _buildStatBox(
                  label: 'VELOCIDAD PICO',
                  value: maxVel.toStringAsFixed(1),
                  unit: 'km/h',
                  sub: 'Récord histórico',
                  valueColor: SpeeDGATheme.neonLime,
                  subColor: SpeeDGATheme.textSecondary,
                ),
              ],
            ),
          ),

          // Barra de desgaste de cadena & revisión
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Desgaste de Cadena & Revisión',
                      style: TextStyle(fontSize: 11, color: SpeeDGATheme.textSecondary, fontFamily: SpeeDGATheme.fontJetBrainsMono),
                    ),
                    Text(
                      '${chainWearPct.toStringAsFixed(0)}% (${kmRestantes.toStringAsFixed(0)} km rest.)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: SpeeDGATheme.neonLime,
                        fontFamily: SpeeDGATheme.fontJetBrainsMono,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: chainWearPct / 100.0,
                    backgroundColor: const Color(0xFF1B232D),
                    valueColor: const AlwaysStoppedAnimation<Color>(SpeeDGATheme.neonLime),
                    minHeight: 5.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required String unit,
    required String sub,
    required Color valueColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1217),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpeeDGATheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: SpeeDGATheme.fontSpaceGrotesk,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: SpeeDGATheme.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: SpeeDGATheme.fontJetBrainsMono,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: SpeeDGATheme.neonLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              color: subColor,
              fontFamily: SpeeDGATheme.fontJetBrainsMono,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de una Salida Individual (Rediseño Stitch)
  Widget _buildRideItemCard(Trip trip, int index) {
    final localTime = trip.fechaRegistro.toLocal();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(localTime);
    final isToday = DateTime.now().difference(localTime).inDays == 0;

    String tagLabel = isToday ? 'HOY' : (index == 0 ? 'ÚLTIMA RUTA' : 'GRAVEL TRACK');
    Color tagColor = isToday ? SpeeDGATheme.neonLime : SpeeDGATheme.aeroCyan;

    return Container(
      decoration: SpeeDGATheme.bentoCardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Icono, Título, Tag y Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.directions_bike, color: tagColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Salida ${trip.id ?? (index + 1)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tagLabel,
                              style: TextStyle(
                                fontFamily: SpeeDGATheme.fontJetBrainsMono,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: tagColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: SpeeDGATheme.textSecondary,
                          fontFamily: SpeeDGATheme.fontJetBrainsMono,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Botones de acción: Compartir GPX, Ver Mapa, Borrar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: SpeeDGATheme.warningAmber, size: 18),
                    tooltip: 'Compartir GPX',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _exportGpx(trip),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: SpeeDGATheme.aeroCyan, size: 20),
                    tooltip: 'Ver Mapa',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _navigateToMap(trip),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: SpeeDGATheme.pulseRed, size: 18),
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showDeleteConfirmation(trip.id!),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: SpeeDGATheme.darkBorder, height: 16),

          // Métricas en cuadrícula horizontal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripMetric(
                label: 'DIST.',
                value: '${trip.distanciaKm.toStringAsFixed(2)} km',
                icon: Icons.straighten,
                color: Colors.white,
              ),
              _buildTripMetric(
                label: 'MEDIA',
                value: '${trip.velocidadMediaKmh.toStringAsFixed(1)} km/h',
                icon: Icons.speed,
                color: SpeeDGATheme.neonLime,
              ),
              _buildTripMetric(
                label: 'DESNIVEL',
                value: '+${trip.desnivelPositivoM.toStringAsFixed(0)} m',
                icon: Icons.terrain,
                color: Colors.white,
              ),
              _buildTripMetric(
                label: 'TIEMPO',
                value: trip.formattedMovingTime,
                icon: Icons.timer_outlined,
                color: Colors.white,
              ),
            ],
          ),

          // Minigráfico de Altitud (Sparkline)
          if (trip.rutaCoordenadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'PERFIL ALTITUD',
                  style: TextStyle(
                    fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: SpeeDGATheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SparklineElevationChart(
                    points: trip.rutaCoordenadas,
                    height: 24,
                    primaryColor: tagColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: SpeeDGATheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: SpeeDGATheme.fontSpaceGrotesk,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: SpeeDGATheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: SpeeDGATheme.fontSpaceGrotesk,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color,
          ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SpeeDGATheme.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: SpeeDGATheme.darkBorder),
              ),
              child: const Icon(Icons.directions_bike, size: 40, color: SpeeDGATheme.neonLime),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes salidas registradas',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pulsa el botón de inicio en el velocímetro para salir a rodar.',
              style: TextStyle(color: SpeeDGATheme.textSecondary, fontSize: 12),
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
          backgroundColor: SpeeDGATheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: SpeeDGATheme.darkBorder),
          ),
          title: const Text('Confirmar borrado', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¿Estás seguro de que quieres eliminar esta salida? Esta acción no se puede deshacer.',
            style: TextStyle(color: SpeeDGATheme.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: SpeeDGATheme.textMuted)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SpeeDGATheme.pulseRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
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
