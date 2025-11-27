import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  Future<void> registerClient({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final appUser = AppUser(
      id: cred.user!.uid,
      email: email,
      displayName: displayName,
      role: 'client', // SIEMPRE cliente al registrarse
    );
    await _userService.createUser(appUser);
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
