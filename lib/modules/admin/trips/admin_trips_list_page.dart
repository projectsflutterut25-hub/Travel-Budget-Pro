import 'package:flutter/material.dart';

class AdminTripsListPage extends StatelessWidget {
  const AdminTripsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viajes')),
      body: const Center(
        child: Text('Listado de viajes (pendiente implementar)'),
      ),
    );
  }
}
