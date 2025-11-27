import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';

class DriverService {
  final _col = FirebaseFirestore.instance.collection('drivers');

  Stream<List<Driver>> getAvailableDriversForVehicle(String vehicleType) {
    return _col
        .where('available', isEqualTo: true)
        .where('vehicleType', isEqualTo: vehicleType)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Driver.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> setAvailability(String driverId, bool available) {
    return _col.doc(driverId).update({'available': available});
  }

  Future<List<Driver>> getAllDriversOnce() async {
    final snap = await _col.get();
    return snap.docs.map((doc) => Driver.fromMap(doc.id, doc.data())).toList();
  }
}
