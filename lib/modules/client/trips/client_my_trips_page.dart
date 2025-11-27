import 'package:flutter/material.dart';
import '../../../models/app_user.dart';

class ClientMyTripsPage extends StatelessWidget {
  final AppUser client;

  const ClientMyTripsPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis viajes')),
      body: Center(
        child: Text(
          'Listado de viajes del cliente ${client.displayName ?? client.email}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
