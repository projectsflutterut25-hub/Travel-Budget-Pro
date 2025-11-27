import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_route.dart';

class RouteService {
  final _col = FirebaseFirestore.instance.collection('routes');

  Stream<List<TravelRoute>> listenRoutes() {
    return _col
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TravelRoute.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> createRoute(TravelRoute route) async {
    await _col.add(route.toMap()..['createdAt'] = FieldValue.serverTimestamp());
  }

  Future<void> updateRoute(TravelRoute route) async {
    await _col.doc(route.id).update(route.toMap());
  }

  Future<void> deleteRoute(String id) async {
    await _col.doc(id).delete();
  }
}
