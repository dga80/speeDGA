
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final List<Map<String, double>> routeCoordinates;

  const MapScreen({super.key, required this.routeCoordinates});

  @override
  Widget build(BuildContext context) {
    final List<LatLng> polylinePoints = routeCoordinates
        .map((coord) => LatLng(coord['lat']!, coord['lng']!))
        .toList();

    // Calcular el centro del mapa
    LatLng center = LatLng(0, 0);
    if (polylinePoints.isNotEmpty) {
      double avgLat = polylinePoints.map((p) => p.latitude).reduce((a, b) => a + b) / polylinePoints.length;
      double avgLng = polylinePoints.map((p) => p.longitude).reduce((a, b) => a + b) / polylinePoints.length;
      center = LatLng(avgLat, avgLng);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualización del Trayecto'),
        backgroundColor: Colors.black,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: center, // CORREGIDO: center -> initialCenter
          initialZoom: 14.0,   // CORREGIDO: zoom -> initialZoom
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 5.0,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
