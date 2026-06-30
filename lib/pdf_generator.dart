import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class PdfGenerator {
  static Future<void> generarFactura(Map<String, dynamic> venta, bool aplicarImpuesto, double ivaConfigurado) async {
    final pdf = pw.Document();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

    // Cálculos seguros para evitar el error de 'null'
    double subtotal = (venta['total'] as num?)?.toDouble() ?? 0.0;
    double valorIva = aplicarImpuesto ? (subtotal * (ivaConfigurado / 100)) : 0.0;
    double totalFinal = subtotal + valorIva;

    List<dynamic> productosRaw = [];
    try { productosRaw = jsonDecode(venta['productos_detalle']); } catch (e) { productosRaw = []; }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(child: pw.Text(ajustes['nombre_negocio'] ?? 'RECIBO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Text("NIT: ${ajustes['nit'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
              pw.Text("Dir: ${ajustes['direccion'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
              pw.Divider(thickness: 1),

              // Tabla de productos mejorada
              pw.Table.fromTextArray(
                headers: ['Producto', 'Cant', 'Total'],
                data: productosRaw.map((p) => [p['nombre'], p['cant'].toString(), "\$${(p['total'] as num).toInt()}"]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 7),
                columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
              ),

              pw.Spacer(),

              // Bloque de Totales
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text("Subtotal: \$${subtotal.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                  if (aplicarImpuesto) pw.Text("IVA (${ivaConfigurado.toInt()}%): \$${valorIva.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                  pw.Divider(thickness: 0.5),
                  pw.Text("TOTAL: \$${totalFinal.toInt()}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ]),
              ),

              pw.SizedBox(height: 10),
              // Pie de página con datos bancarios
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                color: PdfColors.grey100,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text("Cuentas Bancarias:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6)),
                  pw.Text("Nequi: ${ajustes['nequi'] ?? 'N/A'} | Daviplata: ${ajustes['daviplata'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 6)),
                ]),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}