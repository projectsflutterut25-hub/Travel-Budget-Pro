import 'package:flutter/material.dart';

// MODELO DE USUARIO
import '../../models/app_user.dart';

// SERVICIO DE AUTENTICACIÓN  <<< FALTABA
import '../../services/auth_service.dart';

// PANTALLA DE LOGIN <<< FALTABA
import '../auth/login_page.dart';

// IMPORTA LAS PANTALLAS DE VIAJES (ESTAS SÍ YA LAS TENÍAS)
import 'trips/client_new_trip_page.dart';
import 'trips/client_my_trips_page.dart';

class ClientHomePage extends StatelessWidget {
  final AppUser user;
  const ClientHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TravelBudget Pro - Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();

              // EVITAR WARNING DE BuildContext
              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Nuevo viaje'),
            subtitle: const Text('Agendar viaje y ver costo'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClientNewTripPage(client: user),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Mis viajes'),
            subtitle: const Text('Estado, cancelaciones y detalle'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ClientMyTripsPage(client: user),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
