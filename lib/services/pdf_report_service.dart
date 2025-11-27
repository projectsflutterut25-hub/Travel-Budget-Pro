import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfReportService {
  final _db = FirebaseFirestore.instance;

  Future<void> generateAdminReportPdf() async {
    final tripsSnap = await _db.collection('trips').get();
    final driversSnap = await _db.collection('drivers').get();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final trips = tripsSnap.docs;

          final completed = trips
              .where((t) => t['status'] == 'completed')
              .toList();
          final scheduled = trips
              .where((t) => t['status'] == 'scheduled')
              .toList();
          final cancelled = trips
              .where((t) => t['status'] == 'cancelled')
              .toList();

          // Ingreso total = viajes completados + penalizaciones
          final income = trips.fold<double>(0, (sum, t) {
            final status = t['status'] ?? '';
            final total = ((t['totalCost'] ?? 0) as num).toDouble();
            final penalty = ((t['penaltyAmount'] ?? 0) as num).toDouble();
            final base = status == 'completed' ? total : 0.0;
            return sum + base + penalty;
          });

          return [
            pw.Text(
              'Reporte General TravelBudget Pro',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Resumen de viajes'),
            pw.SizedBox(height: 8),
            pw.Bullet(text: 'Completados: ${completed.length}'),
            pw.Bullet(text: 'Agendados: ${scheduled.length}'),
            pw.Bullet(text: 'Cancelados: ${cancelled.length}'),
            pw.Bullet(
              text:
                  'Ingresos totales (viajes + penalizaciones): \$${income.toStringAsFixed(2)} MXN',
            ),
            pw.SizedBox(height: 16),

            // ---------------- DETALLE DE VIAJES CON DESGLOSE ----------------
            pw.Text(
              'Detalle de viajes (ingresos y desglose)',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: [
                'Fecha',
                'Cliente',
                'Ruta',
                'Vehículo',
                'Dist. (km)',
                'Tiempo (min)',
                'Total (MXN)',
                'Penalización',
                'Ingreso',
                'Estado',
                'Conductor',
              ],
              data: trips.map((t) {
                final data = t.data();
                final status = data['status'] ?? '';

                // total y penalización
                final total = ((data['totalCost'] ?? 0) as num).toDouble();
                final penalty = ((data['penaltyAmount'] ?? 0) as num)
                    .toDouble();

                // Ingreso efectivo: solo suma total completo si está "completed" + penalización
                final ingreso = (status == 'completed' ? total : 0.0) + penalty;

                // Desglose guardado en pricingBreakdown
                final pb =
                    (data['pricingBreakdown'] ?? <String, dynamic>{})
                        as Map<String, dynamic>;

                final distanceKm = ((pb['distanceKm'] ?? 0) as num).toDouble();
                final durationMin = ((pb['durationMin'] ?? 0) as num)
                    .toDouble();

                final dateStr = (data['dateTime'] as Timestamp)
                    .toDate()
                    .toString()
                    .substring(0, 16);

                final driverName = data['driverName'] ?? '';

                return [
                  dateStr,
                  data['clientName'] ?? '',
                  data['routeName'] ?? '',
                  data['vehicleType'] ?? '',
                  distanceKm.toStringAsFixed(1),
                  durationMin.toStringAsFixed(0),
                  total.toStringAsFixed(2),
                  penalty.toStringAsFixed(2),
                  ingreso.toStringAsFixed(2),
                  status,
                  driverName,
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),

            pw.SizedBox(height: 20),

            // ---------------- CONDUCTORES ----------------
            pw.Text(
              'Conductores',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['Nombre', 'Teléfono', 'Vehículo', 'Disponible'],
              data: driversSnap.docs.map((d) {
                final data = d.data();
                return [
                  data['name'] ?? '',
                  data['phone'] ?? '',
                  data['vehicleType'] ?? '',
                  (data['available'] ?? true) ? 'Sí' : 'No',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
