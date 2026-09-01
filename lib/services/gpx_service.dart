import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';

/// Servicio para generar y compartir archivos estándar GPX 1.1 compatibles con Strava, Garmin y Wikiloc
class GpxService {
  /// Convierte un objeto Trip en una cadena XML GPX 1.1 válida
  static String generateGpx(Trip trip) {
    final dateFormatter = DateFormat('yyyy-MM-ddTHH:mm:ss\'Z\'');
    final formattedDate = dateFormatter.format(trip.fechaRegistro.toUtc());

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="speeDGA Bike Computer" ');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1" ');
    buffer.writeln('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ');
    buffer.writeln('  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');
    
    // Metadatos
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>Salida en Bicicleta speeDGA - ${DateFormat('dd/MM/yyyy HH:mm').format(trip.fechaRegistro)}</name>');
    buffer.writeln('    <time>$formattedDate</time>');
    buffer.writeln('  </metadata>');

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>Ruta speeDGA</name>');
    buffer.writeln('    <type>Cycling</type>');
    buffer.writeln('    <trkseg>');

    for (final point in trip.rutaCoordenadas) {
      final pointTime = dateFormatter.format(point.timestamp.toUtc());
      buffer.writeln('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      buffer.writeln('        <ele>${point.altitude.toStringAsFixed(1)}</ele>');
      buffer.writeln('        <time>$pointTime</time>');
      buffer.writeln('        <extensions>');
      // Velocidad en m/s para GPX estándar
      final speedMs = point.speedKmh / 3.6;
      buffer.writeln('          <speed>${speedMs.toStringAsFixed(2)}</speed>');
      buffer.writeln('        </extensions>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Guarda el GPX en almacenamiento temporal y abre la hoja de compartir nativa
  static Future<void> shareTripGpx(Trip trip) async {
    if (trip.rutaCoordenadas.isEmpty) {
      throw Exception('Este trayecto no contiene puntos de ruta GPS para exportar.');
    }

    final gpxContent = generateGpx(trip);
    final tempDir = await getTemporaryDirectory();
    final fileName = 'speedga_ride_${trip.fechaRegistro.millisecondsSinceEpoch}.gpx';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(gpxContent);

    final xFile = XFile(file.path, mimeType: 'application/gpx+xml');
    await Share.shareXFiles(
      [xFile],
      text: 'Salida en bicicleta speeDGA (${trip.distanciaKm.toStringAsFixed(2)} km, +${trip.desnivelPositivoM.toStringAsFixed(0)} m)',
      subject: 'Ruta speeDGA GPX',
    );
  }
}
