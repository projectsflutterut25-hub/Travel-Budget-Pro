import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

import '../../models/trip.dart';
import '../../models/driver.dart';
import '../../services/trip_service.dart';
import '../../services/driver_service.dart';
import '../../services/pdf_report_service.dart';

import '../../services/tariff_service.dart';
import '../../models/tariff_config.dart';

// >>> IMPORTS PARA RUTAS <<<
import '../../models/travel_route.dart';
import '../../services/route_service.dart';
import '../../services/google_maps_service.dart';

class AdminHomePage extends StatefulWidget {
  final AppUser user;

  const AdminHomePage({super.key, required this.user});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

enum AdminSection { reports, pricing, routes, drivers, users }

class _AdminHomePageState extends State<AdminHomePage> {
  final _authService = AuthService();
  AdminSection _selected = AdminSection.reports;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AdminSidebar(
            userName: widget.user.displayName ?? widget.user.email,
            selected: _selected,
            onSelect: (section) {
              setState(() => _selected = section);
            },
            onLogout: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF3F4F6),
              child: _buildSectionContent(_selected),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(AdminSection section) {
    switch (section) {
      case AdminSection.reports:
        return const _ReportsView();
      case AdminSection.pricing:
        return const _PricingView();
      case AdminSection.routes:
        return const _RoutesView();
      case AdminSection.drivers:
        return const _DriversView();
      case AdminSection.users:
        return const _UsersView();
    }
  }
}

/// ------------------------ SIDEBAR ------------------------

class _AdminSidebar extends StatelessWidget {
  final String userName;
  final AdminSection selected;
  final ValueChanged<AdminSection> onSelect;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.userName,
    required this.selected,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0F3A8A);

    return Container(
      width: 260,
      color: blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Icon(Icons.directions_car, color: Colors.white, size: 26),
                SizedBox(width: 8),
                Text(
                  'Sistema de Viajes',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              'Panel de Administrador',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          _SidebarItem(
            icon: Icons.insert_chart_outlined,
            label: 'Reportes',
            selected: selected == AdminSection.reports,
            onTap: () => onSelect(AdminSection.reports),
          ),
          _SidebarItem(
            icon: Icons.attach_money,
            label: 'Tarifas',
            selected: selected == AdminSection.pricing,
            onTap: () => onSelect(AdminSection.pricing),
          ),
          _SidebarItem(
            icon: Icons.alt_route,
            label: 'Rutas',
            selected: selected == AdminSection.routes,
            onTap: () => onSelect(AdminSection.routes),
          ),
          _SidebarItem(
            icon: Icons.directions_car_filled,
            label: 'Conductores',
            selected: selected == AdminSection.drivers,
            onTap: () => onSelect(AdminSection.drivers),
          ),
          _SidebarItem(
            icon: Icons.group,
            label: 'Usuarios',
            selected: selected == AdminSection.users,
            onTap: () => onSelect(AdminSection.users),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SidebarItem(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            selected: false,
            onTap: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white.withOpacity(0.12) : Colors.transparent;
    final color = Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// ------------------------ REPORTES ------------------------

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  final _tripService = TripService();
  final _driverService = DriverService();
  final _pdfService = PdfReportService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Trip>>(
      stream: _tripService.getAllTrips(),
      builder: (context, snapshot) {
        final allTrips = snapshot.data ?? [];

        final completed = allTrips
            .where((t) => t.status == 'completed')
            .toList();
        final scheduled = allTrips
            .where((t) => t.status == 'scheduled')
            .toList();
        final cancelled = allTrips
            .where((t) => t.status == 'cancelled')
            .toList();

        final income = allTrips.fold<double>(0, (sum, t) {
          final base = t.status == 'completed' ? t.totalCost : 0.0;
          return sum + base + t.penaltyAmount;
        });

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Resumen de Viajes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      await _pdfService.generateAdminReportPdf();
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Reporte PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _MetricCard(
                    title: 'Completados',
                    value: '${completed.length}',
                    icon: Icons.bar_chart,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Agendados',
                    value: '${scheduled.length}',
                    icon: Icons.access_time,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Cancelados',
                    value: '${cancelled.length}',
                    icon: Icons.person_off_outlined,
                  ),
                  const SizedBox(width: 16),
                  _MetricCard(
                    title: 'Ingresos',
                    value: '\$${income.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Viajes Agendados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<List<Trip>>(
                    stream: _tripService.getScheduledTrips(),
                    builder: (context, scheduledSnap) {
                      final trips = scheduledSnap.data ?? [];
                      if (trips.isEmpty) {
                        return const Center(
                          child: Text('No hay viajes agendados.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: trips.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return _ScheduledTripTile(
                            trip: trip,
                            driverService: _driverService,
                            tripService: _tripService,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduledTripTile extends StatefulWidget {
  final Trip trip;
  final DriverService driverService;
  final TripService tripService;

  const _ScheduledTripTile({
    required this.trip,
    required this.driverService,
    required this.tripService,
  });

  @override
  State<_ScheduledTripTile> createState() => _ScheduledTripTileState();
}

class _ScheduledTripTileState extends State<_ScheduledTripTile> {
  String? _selectedDriverId;
  Driver? _selectedDriver;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.routeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.clientName,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.dateTime} | ${trip.passengers} pasajero(s) | ${trip.vehicleType} | \$${trip.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                if (trip.driverName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Conductor: ${trip.driverName} (${trip.driverPhone})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: StreamBuilder<List<Driver>>(
              stream: widget.driverService.getAvailableDriversForVehicle(
                trip.vehicleType,
              ),
              builder: (context, snapshot) {
                final drivers = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  initialValue: _selectedDriverId,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    labelText: 'Asignar conductor',
                  ),
                  items: drivers.map((d) {
                    return DropdownMenuItem(
                      value: d.id,
                      child: Text(d.name),
                      onTap: () {
                        _selectedDriver = d;
                      },
                    );
                  }).toList(),
                  onChanged: (id) async {
                    setState(() => _selectedDriverId = id);
                    if (id != null && _selectedDriver != null) {
                      await widget.tripService.assignDriverToTrip(
                        tripId: trip.id,
                        driverId: _selectedDriver!.id,
                        driverName: _selectedDriver!.name,
                        driverPhone: _selectedDriver!.phone,
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
            ),
            onPressed: () async {
              await widget.tripService.completeTrip(trip);
            },
            child: const Text('Completar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () async {
              await widget.tripService.cancelTripWithPenalty(trip);
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFF7C3AED) : Colors.black87;
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------ TARIFAS ------------------------

class _PricingView extends StatefulWidget {
  const _PricingView();

  @override
  State<_PricingView> createState() => _PricingViewState();
}

class _PricingViewState extends State<_PricingView> {
  final _tariffService = TariffService();

  final _baseFareCtrl = TextEditingController();
  final _pricePerKmCtrl = TextEditingController();
  final _pricePerMinCtrl = TextEditingController();
  final _pricePerTollCtrl = TextEditingController();
  final _fuelCostPerKmCtrl = TextEditingController();

  final _extraSedanCtrl = TextEditingController();
  final _extraSUVCtrl = TextEditingController();
  final _extraVanCtrl = TextEditingController();
  final _extraPickupCtrl = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await _tariffService.getConfigOnce();
    _baseFareCtrl.text = cfg.baseFare.toString();
    _pricePerKmCtrl.text = cfg.pricePerKm.toString();
    _pricePerMinCtrl.text = cfg.pricePerMinute.toString();
    _pricePerTollCtrl.text = cfg.pricePerToll.toString();
    _fuelCostPerKmCtrl.text = cfg.fuelCostPerKm.toString();

    _extraSedanCtrl.text = cfg.extraSedan.toString();
    _extraSUVCtrl.text = cfg.extraSUV.toString();
    _extraVanCtrl.text = cfg.extraVan.toString();
    _extraPickupCtrl.text = cfg.extraPickup.toString();

    setState(() => _loading = false);
  }

  double _parse(TextEditingController c, double def) {
    return double.tryParse(c.text.replaceAll(',', '.')) ?? def;
  }

  Future<void> _saveConfig() async {
    final config = TariffConfig(
      baseFare: _parse(_baseFareCtrl, 50),
      pricePerKm: _parse(_pricePerKmCtrl, 10),
      pricePerMinute: _parse(_pricePerMinCtrl, 2),
      pricePerToll: _parse(_pricePerTollCtrl, 35),
      fuelCostPerKm: _parse(_fuelCostPerKmCtrl, 0.15),
      extraSedan: _parse(_extraSedanCtrl, 0),
      extraSUV: _parse(_extraSUVCtrl, 50),
      extraVan: _parse(_extraVanCtrl, 80),
      extraPickup: _parse(_extraPickupCtrl, 40),
      currency: 'MXN',
    );

    await _tariffService.saveConfig(config);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarifas actualizadas (MXN).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Tarifas (MXN)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Tarifa Base (MXN)',
                            controller: _baseFareCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Kilómetro (MXN/km)',
                            controller: _pricePerKmCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Minuto (MXN/min)',
                            controller: _pricePerMinCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Caseta (MXN)',
                            controller: _pricePerTollCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LabeledTextField(
                      label: 'Consumo Combustible (MXN/km)',
                      controller: _fuelCostPerKmCtrl,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tarifas por Tipo de Vehículo (recargo fijo MXN)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Sedan (Extra MXN)',
                            controller: _extraSedanCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'SUV (Extra MXN)',
                            controller: _extraSUVCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Van (Extra MXN)',
                            controller: _extraVanCtrl,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Pickup (Extra MXN)',
                            controller: _extraPickupCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _saveConfig,
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _LabeledTextField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// ------------------------ RUTAS ------------------------

class _RoutesView extends StatefulWidget {
  const _RoutesView();

  @override
  State<_RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<_RoutesView> {
  final _routeService = RouteService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rutas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                onPressed: () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => _RouteFormDialog(
                      title: 'Nueva Ruta',
                      onSubmit: (route) async {
                        await _routeService.createRoute(route);
                      },
                    ),
                  );
                },
                child: const Text('+ Nueva Ruta'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: StreamBuilder<List<TravelRoute>>(
                stream: _routeService.listenRoutes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final routes = snapshot.data ?? [];
                  if (routes.isEmpty) {
                    return const Center(
                      child: Text('No hay rutas registradas.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final r = routes[index];
                      return _RouteListItem(
                        route: r,
                        onEdit: () async {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => _RouteFormDialog(
                              title: 'Editar Ruta',
                              initialRoute: r,
                              onSubmit: (updated) async {
                                await _routeService.updateRoute(updated);
                              },
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar ruta'),
                              content: Text(
                                '¿Seguro que deseas eliminar la ruta "${r.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Aceptar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _routeService.deleteRoute(r.id);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteListItem extends StatelessWidget {
  final TravelRoute route;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RouteListItem({
    required this.route,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        route.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${route.originAddress} → ${route.destAddress}\n'
        'Distancia: ${route.distanceKm.toStringAsFixed(1)} km | '
        'Tiempo: ${route.durationMin.toStringAsFixed(0)} min | '
        'Casetas: ${route.tollsCount}',
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 12,
        children: [
          TextButton(onPressed: onEdit, child: const Text('Editar')),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _RouteFormDialog extends StatefulWidget {
  final String title;
  final TravelRoute? initialRoute;
  final Future<void> Function(TravelRoute route) onSubmit;

  const _RouteFormDialog({
    required this.title,
    this.initialRoute,
    required this.onSubmit,
  });

  @override
  State<_RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<_RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mapsService = GoogleMapsService();

  late TextEditingController _nameCtrl;
  late TextEditingController _originCtrl;
  late TextEditingController _destCtrl;
  late TextEditingController _tollsCtrl;

  double _originLat = 0;
  double _originLng = 0;
  double _destLat = 0;
  double _destLng = 0;
  double _distanceKm = 0;
  double _durationMin = 0;

  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRoute;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _originCtrl = TextEditingController(text: r?.originAddress ?? '');
    _destCtrl = TextEditingController(text: r?.destAddress ?? '');
    _tollsCtrl = TextEditingController(text: r?.tollsCount.toString() ?? '0');

    _originLat = r?.originLat ?? 0;
    _originLng = r?.originLng ?? 0;
    _destLat = r?.destLat ?? 0;
    _destLng = r?.destLng ?? 0;
    _distanceKm = r?.distanceKm ?? 0;
    _durationMin = r?.durationMin ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _tollsCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    if (_originCtrl.text.isEmpty || _destCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escribe origen y destino')));
      return;
    }

    setState(() => _calculating = true);

    try {
      final (oLat, oLng) = await _mapsService.geocodeAddress(_originCtrl.text);
      final (dLat, dLng) = await _mapsService.geocodeAddress(_destCtrl.text);

      final (distanceKm, durationMin) = await _mapsService
          .getDistanceAndDuration(
            originLat: oLat,
            originLng: oLng,
            destLat: dLat,
            destLng: dLng,
          );

      setState(() {
        _originLat = oLat;
        _originLng = oLng;
        _destLat = dLat;
        _destLng = dLng;
        _distanceKm = distanceKm;
        _durationMin = durationMin;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al calcular la ruta: $e')));
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_distanceKm <= 0 || _durationMin <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calcula la ruta (km y minutos) antes de guardar.'),
        ),
      );
      return;
    }

    final tolls = int.tryParse(_tollsCtrl.text) ?? 0;

    final route = TravelRoute(
      id: widget.initialRoute?.id ?? '',
      name: _nameCtrl.text.trim(),
      originAddress: _originCtrl.text.trim(),
      destAddress: _destCtrl.text.trim(),
      originLat: _originLat,
      originLng: _originLng,
      destLat: _destLat,
      destLng: _destLng,
      distanceKm: _distanceKm,
      durationMin: _durationMin,
      tollsCount: tolls,
    );

    await widget.onSubmit(route);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Ruta',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa un nombre'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _originCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Punto de Origen (dirección)',
                    hintText:
                        'Ej: Av. Insurgentes Sur 123, Ciudad de México, CDMX',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el origen'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _destCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Punto de Destino (dirección)',
                    hintText:
                        'Ej: Aeropuerto Internacional CDMX, Ciudad de México',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el destino'
                      : null,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cálculo Automático',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _distanceKm > 0
                                      ? _distanceKm.toStringAsFixed(1)
                                      : '--',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                                const Text('Kilómetros'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _durationMin > 0
                                      ? _durationMin.toStringAsFixed(0)
                                      : '--',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const Text('Minutos'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _tollsCtrl,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text('Caseta(s)'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _calculating ? null : _calculateRoute,
                          icon: _calculating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.map),
                          label: const Text('Calcular con Maps'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------ CONDUCTORES ------------------------

class _DriversView extends StatelessWidget {
  const _DriversView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Conductores',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                onPressed: () {
                  // TODO: abrir formulario "Nuevo Conductor"
                },
                child: const Text('+ Nuevo Conductor'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                children: const [
                  _DriverListItem(
                    name: 'Juan Pérez',
                    phone: 'Tel: 555-1234',
                    car: 'Toyota Corolla 2020 - ABC-123',
                    available: true,
                  ),
                  _DriverListItem(
                    name: 'María García',
                    phone: 'Tel: 555-5678',
                    car: 'Honda Civic 2021 - XYZ-789',
                    available: true,
                  ),
                  _DriverListItem(
                    name: 'Carlos López',
                    phone: 'Tel: 555-9012',
                    car: 'Nissan Sentra 2019 - DEF-456',
                    available: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverListItem extends StatelessWidget {
  final String name;
  final String phone;
  final String car;
  final bool available;

  const _DriverListItem({
    required this.name,
    required this.phone,
    required this.car,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(initial, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$phone\n$car'),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Disponible'),
              const SizedBox(width: 4),
              Checkbox(
                value: available,
                onChanged: (v) {
                  // TODO: actualizar disponibilidad en Firestore
                },
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // TODO: editar conductor
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: eliminar conductor
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// ------------------------ USUARIOS ------------------------

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Usuarios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                children: const [
                  _UserListItem(
                    name: 'Admin Principal',
                    email: 'admin@viajes.com',
                    date: '2024-01-15',
                    isAdmin: true,
                  ),
                  _UserListItem(
                    name: 'Pedro Martínez',
                    email: 'pedro@email.com',
                    date: '2024-02-20',
                    isAdmin: false,
                  ),
                  _UserListItem(
                    name: 'Ana Rodríguez',
                    email: 'ana@email.com',
                    date: '2024-03-10',
                    isAdmin: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final String name;
  final String email;
  final String date;
  final bool isAdmin;

  const _UserListItem({
    required this.name,
    required this.email,
    required this.date,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF7C3AED),
        child: Text(initial, style: const TextStyle(color: Colors.white)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$email\nRegistrado: $date'),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Administrador'),
          const SizedBox(width: 4),
          Checkbox(
            value: isAdmin,
            onChanged: (v) {
              // TODO: actualizar rol en Firestore (admin / client)
            },
          ),
        ],
      ),
    );
  }
}
