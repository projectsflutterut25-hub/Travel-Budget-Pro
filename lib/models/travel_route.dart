class TravelRoute {
  final String id;
  final String name;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  TravelRoute({
    required this.id,
    required this.name,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  factory TravelRoute.fromMap(String id, Map<String, dynamic> data) {
    return TravelRoute(
      id: id,
      name: data['name'] ?? '',
      originLat: (data['originLat'] ?? 0).toDouble(),
      originLng: (data['originLng'] ?? 0).toDouble(),
      destLat: (data['destLat'] ?? 0).toDouble(),
      destLng: (data['destLng'] ?? 0).toDouble(),
    );
  }
}
