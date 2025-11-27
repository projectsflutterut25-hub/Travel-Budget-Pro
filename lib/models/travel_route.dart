import 'package:cloud_firestore/cloud_firestore.dart';

class TravelRoute {
  final String id;
  final String name;
  final String originAddress;
  final String destAddress;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final double distanceKm;
  final double durationMin;
  final int tollsCount; // casetas

  TravelRoute({
    required this.id,
    required this.name,
    required this.originAddress,
    required this.destAddress,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.distanceKm,
    required this.durationMin,
    required this.tollsCount,
  });

  factory TravelRoute.fromMap(String id, Map<String, dynamic> data) {
    return TravelRoute(
      id: id,
      name: data['name'] ?? '',
      originAddress: data['originAddress'] ?? '',
      destAddress: data['destAddress'] ?? '',
      originLat: (data['originLat'] ?? 0).toDouble(),
      originLng: (data['originLng'] ?? 0).toDouble(),
      destLat: (data['destLat'] ?? 0).toDouble(),
      destLng: (data['destLng'] ?? 0).toDouble(),
      distanceKm: (data['distanceKm'] ?? 0).toDouble(),
      durationMin: (data['durationMin'] ?? 0).toDouble(),
      tollsCount: (data['tollsCount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'originAddress': originAddress,
      'destAddress': destAddress,
      'originLat': originLat,
      'originLng': originLng,
      'destLat': destLat,
      'destLng': destLng,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'tollsCount': tollsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
