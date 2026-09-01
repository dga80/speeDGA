import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de información meteorológica optimizado para ciclistas (temperatura, lluvia y viento)
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse('$_baseUrl?latitude=$lat&longitude=$lon&current_weather=true');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        return {
          'temperature': (current['temperature'] as num?)?.toDouble() ?? 0.0,
          'weathercode': (current['weathercode'] as num?)?.toInt() ?? 0,
          'windspeed': (current['windspeed'] as num?)?.toDouble() ?? 0.0,
          'winddirection': (current['winddirection'] as num?)?.toDouble() ?? 0.0,
        };
      } else {
        return {};
      }
    } catch (e) {
      return {}; 
    }
  }

  /// Convierte el código meteorológico WMO en un icono/emoji
  String getWeatherIcon(int code) {
    if (code == 0) return "☀️"; // Despejado
    if (code >= 1 && code <= 3) return "⛅"; // Parcialmente nublado
    if (code >= 45 && code <= 48) return "🌫️"; // Niebla
    if (code >= 51 && code <= 67) return "🌧️"; // Lluvia
    if (code >= 71 && code <= 77) return "❄️"; // Nieve
    if (code >= 80 && code <= 82) return "🌦️"; // Chubascos
    if (code >= 95 && code <= 99) return "⛈️"; // Tormenta
    return "🌤️";
  }

  /// Traduce los grados de dirección del viento en rumbo cardinal
  String getWindCardinal(double degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }
}
