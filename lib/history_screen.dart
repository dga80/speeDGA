
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'map_screen.dart'; // Importaremos la pantalla del mapa que crearemos después

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<dynamic>> _futureTrips;

  @override
  void initState() {
    super.initState();
    _futureTrips = _fetchTrips();
  }

  Future<List<dynamic>> _fetchTrips() async {
    final response = await Supabase.instance.client
        .from('registros_velocidad')
        .select()
        .order('fecha_registro', ascending: false);
    
    return response;
  }

  void _deleteTrip(int id) async {
    try {
      await Supabase.instance.client.from('registros_velocidad').delete().match({'id': id});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trayecto borrado correctamente'), backgroundColor: Colors.green),
      );
      setState(() {
        _futureTrips = _fetchTrips(); // Refresh the list
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al borrar el trayecto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToMap(dynamic tripData) {
    final routeCoords = tripData['ruta_coordenadas'];
    if (routeCoords == null || routeCoords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este trayecto no tiene datos de ruta para mostrar.'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // Asumiendo que routeCoords es una lista de mapas con 'lat' y 'lng'
    final List<Map<String, double>> coordsList = (routeCoords as List).map((item) => {'lat': (item['lat'] as num).toDouble(), 'lng': (item['lng'] as num).toDouble()}).toList();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapScreen(routeCoordinates: coordsList)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Trayectos'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _futureTrips,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay trayectos guardados.'));
          }

          final trips = snapshot.data!;

          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final DateTime localTime = DateTime.parse(trip['fecha_registro']).toLocal();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(localTime);

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text('Fecha: $formattedDate', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Distancia: ${trip['distancia_recorrida_km'].toStringAsFixed(2)} km - Vel. Máx: ${trip['velocidad_maxima_kmh'].toStringAsFixed(1)} km/h'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.map_outlined, color: Colors.blueAccent),
                        onPressed: () => _navigateToMap(trip),
                        tooltip: 'Ver Mapa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirmation(trip['id']),
                        tooltip: 'Borrar',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

    void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar borrado'),
          content: const Text('¿Estás seguro de que quieres borrar este trayecto? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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
