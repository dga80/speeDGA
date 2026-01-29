import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      print("🌤️ Solicitando clima para lat=$lat, lon=$lon");
      final url = Uri.parse('$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("🌤️ Respuesta clima: status=${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🌤️ Datos clima recibidos: ${data['current_weather']}");
        return data['current_weather'];
      } else {
        print("❌ Error clima: HTTP ${response.statusCode}");
        throw Exception('Error al cargar clima: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error WeatherService: $e");
      return {}; 
    }
  }

  // Mapeo simple de códigos WMO a Emojis (para evitar más dependencias de iconos por ahora)
  // O podemos usar Icons de Material si el usuario prefiere.
  String getWeatherIcon(int code) {
    if (code == 0) return "☀️"; // Despejado
    if (code >= 1 && code <= 3) return "☁️"; // Nublado
    if (code >= 45 && code <= 48) return "🌫️"; // Niebla
    if (code >= 51 && code <= 67) return "🌧️"; // Lluvia
    if (code >= 71 && code <= 77) return "❄️"; // Nieve
    if (code >= 80 && code <= 82) return "🌦️"; // Chubascos
    if (code >= 95 && code <= 99) return "⛈️"; // Tormenta
    return "❓";
  }
}
