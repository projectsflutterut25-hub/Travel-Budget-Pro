import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/trip.dart';
import '../../models/driver.dart';
import '../../services/trip_service.dart';
import '../../services/driver_service.dart';
import '../../services/pdf_report_service.dart';

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
              color: const Color(0xFFF3F4F6), // gris claro de fondo
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
          // Header
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
          // Menu
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
          // Usuario logueado (opcional)
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
          // Cerrar sesión
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
              // Título + botón PDF
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

              // Tarjetas de métricas conectadas a Firestore
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

              // Lista dinámica de viajes agendados
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
          // Información del viaje
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

          // Dropdown de conductores disponibles por tipo de vehículo
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

          // Botón Completar
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

          // Botón Cancelar (con penalización 50%)
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

class _PricingView extends StatelessWidget {
  const _PricingView();

  @override
  Widget build(BuildContext context) {
    // Por ahora solo UI; luego conectas a Firestore
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Tarifas',
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
                    // Primera fila
                    Row(
                      children: const [
                        Expanded(
                          child: _LabeledTextField(label: 'Tarifa Base (\$)'),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Kilómetro (\$)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Minuto (\$)',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(
                            label: 'Precio por Caseta (\$)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _LabeledTextField(
                      label: 'Consumo Combustible (\$/km)',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tarifas por Tipo de Vehículo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: _LabeledTextField(label: 'Sedan (Extra \$)'),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(label: 'SUV (Extra \$)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(
                          child: _LabeledTextField(label: 'Van (Extra \$)'),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _LabeledTextField(label: 'Pickup (Extra \$)'),
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
                        onPressed: () {
                          // TODO: guardar configuración en Firestore
                        },
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

  const _LabeledTextField({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

/// ------------------------ RUTAS ------------------------

class _RoutesView extends StatelessWidget {
  const _RoutesView();

  @override
  Widget build(BuildContext context) {
    // Por ahora estático; luego lo conectas a la colección "routes"
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
                onPressed: () {
                  // TODO: abrir formulario "Nueva Ruta"
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
              child: ListView(
                children: const [
                  _RouteListItem(
                    title: 'Ruta Centro',
                    subtitle: 'Centro a Aeropuerto',
                    distance: '25 km',
                  ),
                  _RouteListItem(
                    title: 'Ruta Norte',
                    subtitle: 'Zona Norte a Universidad',
                    distance: '15 km',
                  ),
                  _RouteListItem(
                    title: 'Ruta Sur',
                    subtitle: 'Zona Sur a Plaza Central',
                    distance: '20 km',
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

class _RouteListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String distance;

  const _RouteListItem({
    required this.title,
    required this.subtitle,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$subtitle\nDistancia: $distance'),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 12,
        children: [
          TextButton(
            onPressed: () {
              // TODO: editar ruta
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: eliminar ruta
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

/// ------------------------ CONDUCTORES ------------------------

class _DriversView extends StatelessWidget {
  const _DriversView();

  @override
  Widget build(BuildContext context) {
    // Más adelante llenas con Firestore "drivers"
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
    // Luego conectas a Firestore "users"
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
