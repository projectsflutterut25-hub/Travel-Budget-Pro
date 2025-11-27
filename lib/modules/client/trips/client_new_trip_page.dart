import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/app_user.dart';
import '../../../models/travel_route.dart';
import '../../../services/trip_service.dart';
import '../../../services/google_maps_service.dart';

class ClientNewTripPage extends StatefulWidget {
  final AppUser client;

  const ClientNewTripPage({super.key, required this.client});

  @override
  State<ClientNewTripPage> createState() => _ClientNewTripPageState();
}

class _ClientNewTripPageState extends State<ClientNewTripPage> {
  final _tripService = TripService();
  final _mapsService = GoogleMapsService();

  List<TravelRoute> _routes = [];
  TravelRoute? _selectedRoute;

  String _selectedVehicleType = 'Sedan';
  int _passengers = 1;
  DateTime _selectedDateTime = DateTime.now();

  double _distanceKm = 0;
  double _durationMin = 0;
  double _totalCost = 0;

  bool _loadingRoutes = true;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final snap = await FirebaseFirestore.instance.collection('routes').get();

    final list = snap.docs
        .map((d) => TravelRoute.fromMap(d.id, d.data()))
        .toList();

    setState(() {
      _routes = list;
      _loadingRoutes = false;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _calculateCost() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una ruta')));
      return;
    }

    setState(() {
      _calculating = true;
    });

    try {
      // 1) Consultar Google Maps para obtener distancia y tiempo
      final (distanceKm, durationMin) = await _mapsService
          .getDistanceAndDuration(
            originLat: _selectedRoute!.originLat,
            originLng: _selectedRoute!.originLng,
            destLat: _selectedRoute!.destLat,
            destLng: _selectedRoute!.destLng,
          );

      _distanceKm = distanceKm;
      _durationMin = durationMin;

      // 2) Fórmula de tarifa (ejemplo que luego se liga a tarifas del admin)
      const double baseFare = 50; // tarifa base
      const double pricePerKm = 8; // por km
      const double pricePerMin = 1.5; // por minuto
      const double tolls = 0; // casetas (por ahora 0)

      double vehicleMultiplier = 1.0;
      switch (_selectedVehicleType) {
        case 'SUV':
          vehicleMultiplier = 1.3;
          break;
        case 'Van':
          vehicleMultiplier = 1.6;
          break;
        default:
          vehicleMultiplier = 1.0;
      }

      final raw =
          baseFare +
          (distanceKm * pricePerKm) +
          (durationMin * pricePerMin) +
          tolls;

      // +5% por cada pasajero extra
      final passengersFactor = 1 + (_passengers - 1) * 0.05;

      final total = raw * vehicleMultiplier * passengersFactor;

      setState(() {
        _totalCost = double.parse(total.toStringAsFixed(2));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error calculando costo: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _calculating = false;
        });
      }
    }
  }

  Future<void> _confirmTrip() async {
    if (_selectedRoute == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una ruta')));
      return;
    }
    if (_totalCost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calcula el costo antes de confirmar')),
      );
      return;
    }

    await _tripService.createTrip(
      clientId: widget.client.id,
      clientName: widget.client.displayName ?? widget.client.email,
      routeName: _selectedRoute!.name,
      dateTime: _selectedDateTime,
      passengers: _passengers,
      vehicleType: _selectedVehicleType,
      totalCost: _totalCost,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viaje agendado correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F3A8A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo viaje'),
        backgroundColor: primary,
      ),
      body: _loadingRoutes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agendar nuevo viaje',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Ruta
                  const Text(
                    'Ruta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TravelRoute>(
                    value: _selectedRoute,
                    items: _routes
                        .map(
                          (r) =>
                              DropdownMenuItem(value: r, child: Text(r.name)),
                        )
                        .toList(),
                    onChanged: (r) {
                      setState(() => _selectedRoute = r);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona una ruta',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fecha y hora
                  const Text(
                    'Fecha y hora',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedDateTime.toString().substring(0, 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Pasajeros
                  const Text(
                    'Pasajeros',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _passengers,
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _passengers = v!);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tipo de vehículo
                  const Text(
                    'Tipo de vehículo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    items: const [
                      DropdownMenuItem(value: 'Sedan', child: Text('Sedan')),
                      DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                      DropdownMenuItem(value: 'Van', child: Text('Van')),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedVehicleType = v!);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón calcular costo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _calculating ? null : _calculateCost,
                      icon: _calculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate),
                      label: const Text('Calcular costo'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resumen costo/distancia
                  if (_totalCost > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Distancia: ${_distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Duración: ${_durationMin.toStringAsFixed(0)} min',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Costo total estimado:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${_totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botón confirmar viaje
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Confirmar viaje',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
