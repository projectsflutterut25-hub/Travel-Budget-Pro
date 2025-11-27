import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  final _db = FirebaseFirestore.instance;

  Future<void> generateAdminReportPdf() async {
    final tripsSnap = await _db.collection('trips').get();
    final driversSnap = await _db.collection('drivers').get();

    final doc = pw.Document();

    // Página de resumen de viajes
    doc.addPage(
      pw.MultiPage(
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
          final income = trips.fold<double>(
            0,
            (sum, t) =>
                sum +
                ((t['status'] == 'completed' ? (t['totalCost'] ?? 0) : 0)
                        as num)
                    .toDouble() +
                ((t['penaltyAmount'] ?? 0) as num).toDouble(),
          );

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
                  'Ingresos totales (viajes + penalizaciones): \$${income.toStringAsFixed(2)}',
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Detalle de viajes',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: [
                'Fecha',
                'Cliente',
                'Ruta',
                'Estado',
                'Total',
                'Penalización',
                'Conductor',
              ],
              data: trips.map((t) {
                return [
                  (t['dateTime'] as Timestamp).toDate().toString().substring(
                    0,
                    16,
                  ),
                  t['clientName'] ?? '',
                  t['routeName'] ?? '',
                  t['status'] ?? '',
                  '\$${(t['totalCost'] ?? 0).toString()}',
                  '\$${(t['penaltyAmount'] ?? 0).toString()}',
                  t['driverName'] ?? '',
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
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
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
