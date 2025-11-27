import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  // Reemplaza por tu API KEY real de Google Maps
  static const String _apiKey = 'TU_API_KEY_DE_GOOGLE_MAPS';

  /// Consulta Distance Matrix API y regresa (distanciaKm, duracionMinutos)
  Future<(double distanceKm, double durationMinutes)> getDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final origins = '$originLat,$originLng';
    final destinations = '$destLat,$destLng';

    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=$origins'
      '&destinations=$destinations'
      '&mode=driving'
      '&language=es'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error Distance Matrix: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['rows'] == null ||
        data['rows'].isEmpty ||
        data['rows'][0]['elements'] == null ||
        data['rows'][0]['elements'].isEmpty) {
      throw Exception('Respuesta Distance Matrix vacía');
    }

    final element = data['rows'][0]['elements'][0];

    if (element['status'] != 'OK') {
      throw Exception('Distance Matrix status: ${element['status']}');
    }

    final distanceMeters = (element['distance']['value'] as num).toDouble();
    final durationSeconds = (element['duration']['value'] as num).toDouble();

    final distanceKm = distanceMeters / 1000.0;
    final durationMinutes = durationSeconds / 60.0;

    return (distanceKm, durationMinutes);
  }
}
