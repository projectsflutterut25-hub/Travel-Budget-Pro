import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'modules/auth/login_page.dart';
import 'modules/admin/admin_home_page.dart';
import 'modules/client/client_home_page.dart';
import 'services/user_service.dart';
import 'models/app_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const TravelBudgetProApp());
}

class TravelBudgetProApp extends StatelessWidget {
  const TravelBudgetProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelBudget Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3A8A), // azul del sidebar
          primary: const Color(0xFF0F3A8A),
          secondary: const Color(0xFF2563EB),
          surface: const Color(0xFFF3F4F6),
          onSurface: const Color(0xFF111827),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F3A8A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const RootGate(),
    );
  }
}

/// Decide qué pantalla mostrar según auth + rol
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  AppUser? _appUser;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        setState(() {
          _appUser = null;
          _loadingRole = false;
        });
      } else {
        final loadedUser = await UserService().getUserById(
          user.uid,
        ); // Firestore
        setState(() {
          _appUser = loadedUser;
          _loadingRole = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_appUser == null) {
      return const LoginPage();
    }

    if (_appUser!.role == 'admin') {
      return AdminHomePage(user: _appUser!);
    } else {
      return ClientHomePage(user: _appUser!);
    }
  }
}
