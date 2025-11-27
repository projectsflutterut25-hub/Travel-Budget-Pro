import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sugerencia de lugar devuelta por Places Autocomplete
class PlaceSuggestion {
  final String description;
  final String placeId;

  PlaceSuggestion({required this.description, required this.placeId});
}

class GoogleMapsService {
  // TODO: mueve tu API Key a un .env / remoto en producción.
  static const String _apiKey = 'TU_API_KEY_AQUI';

  static const String _baseDirections =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _baseGeocode =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _basePlacesAutocomplete =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _basePlaceDetails =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Distancia (km) y duración (min) entre dos puntos.
  Future<(double, double)> getDistanceAndDuration({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url =
        '$_baseDirections?origin=$originLat,$originLng&destination=$destLat,$destLng'
        '&language=es&region=mx&key=$_apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error Directions API: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    if (data['routes'] == null || data['routes'].isEmpty) {
      throw Exception('Sin rutas en Directions API');
    }

    final leg = data['routes'][0]['legs'][0];
    final distanceMeters = (leg['distance']['value'] as num).toDouble();
    final durationSeconds = (leg['duration']['value'] as num).toDouble();

    final km = distanceMeters / 1000.0;
    final min = durationSeconds / 60.0;
    return (km, min);
  }

  /// Geocodifica una dirección libre -> (lat, lng)
  Future<(double, double)> geocodeAddress(String address) async {
    final url =
        '$_baseGeocode?address=${Uri.encodeComponent(address)}'
        '&language=es&region=mx&key=$_apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error Geocoding API: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    if (data['results'] == null || data['results'].isEmpty) {
      throw Exception('No se encontraron coordenadas para esa dirección');
    }

    final loc = data['results'][0]['geometry']['location'];
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    return (lat, lng);
  }

  /// Autocomplete de direcciones tipo Uber
  Future<List<PlaceSuggestion>> autocompleteAddress(String input) async {
    if (input.trim().isEmpty) return [];

    final url =
        '$_basePlacesAutocomplete'
        '?input=${Uri.encodeComponent(input)}'
        '&language=es'
        '&components=country:mx'
        '&key=$_apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error Places Autocomplete: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    if (data['predictions'] == null) return [];

    return (data['predictions'] as List)
        .map(
          (p) => PlaceSuggestion(
            description: p['description'] as String,
            placeId: p['place_id'] as String,
          ),
        )
        .toList();
  }

  /// Recupera coordenadas a partir de un placeId de Places
  Future<(double, double)> getLatLngFromPlaceId(String placeId) async {
    final url =
        '$_basePlaceDetails'
        '?place_id=$placeId'
        '&language=es'
        '&fields=geometry'
        '&key=$_apiKey';

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Error Place Details: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final result = data['result'];
    if (result == null ||
        result['geometry'] == null ||
        result['geometry']['location'] == null) {
      throw Exception('Sin geometry en Place Details');
    }

    final loc = result['geometry']['location'];
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    return (lat, lng);
  }
}
