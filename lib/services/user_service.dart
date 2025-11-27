import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<void> createUser(AppUser user) async {
    await _users.doc(user.id).set(user.toMap());
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _users.doc(uid).update({'role': role});
  }

  Stream<List<AppUser>> listenUsers() {
    return _users.snapshots().map((snapshot) {
      return snapshot.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    });
  }
}
