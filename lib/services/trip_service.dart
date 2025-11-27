import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';

class TripService {
  final _col = FirebaseFirestore.instance.collection('trips');

  /// Crear un viaje (cuando el cliente confirma la reserva)
  Future<void> createTrip({
    required String clientId,
    required String clientName,
    required String routeName,
    required DateTime dateTime,
    required int passengers,
    required String vehicleType,
    required double totalCost,

    /// NUEVO: mapa con el desglose de tarifas
    Map<String, dynamic>? pricingBreakdown,
  }) async {
    await _col.add({
      'clientId': clientId,
      'clientName': clientName,
      'routeName': routeName,
      'dateTime': Timestamp.fromDate(dateTime),
      'passengers': passengers,
      'vehicleType': vehicleType,
      'totalCost': totalCost,
      'status': 'scheduled', // recién creado = agendado
      'penaltyAmount': 0.0, // sin penalización al inicio
      'driverId': null,
      'driverName': null,
      'driverPhone': null,

      // NUEVO: se guarda el desglose dentro del doc
      'pricingBreakdown': pricingBreakdown,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Viajes agendados (pendientes) para la vista de Reportes
  Stream<List<Trip>> getScheduledTrips() {
    return _col
        .where('status', isEqualTo: 'scheduled')
        .orderBy('dateTime')
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  /// Todos los viajes (para indicadores y PDF)
  Stream<List<Trip>> getAllTrips() {
    return _col
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  Future<void> assignDriverToTrip({
    required String tripId,
    required String driverId,
    required String driverName,
    required String driverPhone,
  }) async {
    await _col.doc(tripId).update({
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeTrip(Trip trip) async {
    await _col.doc(trip.id).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelTripWithPenalty(Trip trip) async {
    final penalty = trip.totalCost * 0.5;
    await _col.doc(trip.id).update({
      'status': 'cancelled',
      'penaltyAmount': penalty,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
