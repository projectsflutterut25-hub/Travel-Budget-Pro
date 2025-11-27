import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String clientId;
  final String clientName;
  final String routeName;
  final DateTime dateTime;
  final int passengers;
  final String vehicleType;
  final double totalCost;
  final String status; // scheduled, completed, cancelled
  final double penaltyAmount;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;

  /// Desglose de tarifas (base, km, minutos, combustible, etc.)
  /// Se guarda como Map para almacenarlo directo en Firestore.
  final Map<String, dynamic>? pricingBreakdown;

  Trip({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.routeName,
    required this.dateTime,
    required this.passengers,
    required this.vehicleType,
    required this.totalCost,
    required this.status,
    required this.penaltyAmount,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.pricingBreakdown,
  });

  factory Trip.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      routeName: data['routeName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      passengers: data['passengers'] ?? 1,
      vehicleType: data['vehicleType'] ?? '',
      totalCost: (data['totalCost'] ?? 0).toDouble(),
      status: data['status'] ?? 'scheduled',
      penaltyAmount: (data['penaltyAmount'] ?? 0).toDouble(),
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      pricingBreakdown:
          data['pricingBreakdown'] as Map<String, dynamic>?, // NUEVO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'routeName': routeName,
      'dateTime': Timestamp.fromDate(dateTime),
      'passengers': passengers,
      'vehicleType': vehicleType,
      'totalCost': totalCost,
      'status': status,
      'penaltyAmount': penaltyAmount,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'pricingBreakdown': pricingBreakdown, // NUEVO
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
