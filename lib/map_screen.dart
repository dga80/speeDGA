import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';

/// Pantalla para visualizar la ruta ciclista en el mapa interactivo con OpenStreetMap
class MapScreen extends StatelessWidget {
  final List<Map<String, double>> routeCoordinates;
  final Trip? trip;

  const MapScreen({
    super.key,
    required this.routeCoordinates,
    this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final List<LatLng> polylinePoints = routeCoordinates
        .map((coord) => LatLng(coord['lat']!, coord['lng']!))
        .toList();

    // Calcular el centro y los límites
    LatLng center = const LatLng(41.3851, 2.1734);
    if (polylinePoints.isNotEmpty) {
      double avgLat = polylinePoints.map((p) => p.latitude).reduce((a, b) => a + b) / polylinePoints.length;
      double avgLng = polylinePoints.map((p) => p.longitude).reduce((a, b) => a + b) / polylinePoints.length;
      center = LatLng(avgLat, avgLng);
    }

    final hasPoints = polylinePoints.isNotEmpty;
    final startPoint = hasPoints ? polylinePoints.first : null;
    final endPoint = hasPoints ? polylinePoints.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta de la Salida'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: hasPoints ? 14.5 : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.danidev.speedga',
              ),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF00FF41), // Verde flúor ciclista
                    ),
                  ],
                ),
              if (hasPoints)
                MarkerLayer(
                  markers: [
                    // Marcador de Inicio (Verde)
                    Marker(
                      point: startPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.greenAccent,
                        size: 32,
                      ),
                    ),
                    // Marcador de Fin (Rojo / Meta)
                    if (polylinePoints.length > 1)
                      Marker(
                        point: endPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.sports_score,
                          color: Colors.redAccent,
                          size: 32,
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // Tarjeta inferior flotante con datos de la ruta (si hay trip disponible)
          if (trip != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('DISTANCIA', '${trip!.distanciaKm.toStringAsFixed(2)} km'),
                    _buildStatItem('VEL. MEDIA', '${trip!.velocidadMediaKmh.toStringAsFixed(1)} km/h'),
                    _buildStatItem('DESNIVEL +', '+${trip!.desnivelPositivoM.toStringAsFixed(0)} m'),
                    _buildStatItem('TIEMPO', trip!.formattedMovingTime),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF00FF41), fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
