import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class PdfGenerator {
  static Future<void> generarFactura(Map<String, dynamic> venta, bool aplicarImpuesto, double ivaConfigurado) async {
    final pdf = pw.Document();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

    // Cálculos seguros
    double subtotal = (venta['total'] as num?)?.toDouble() ?? 0.0;
    double valorIva = aplicarImpuesto ? (subtotal * (ivaConfigurado / 100)) : 0.0;
    double totalFinal = subtotal + valorIva;

    List<dynamic> productosRaw = [];
    try {
      productosRaw = jsonDecode(venta['productos_detalle']);
    } catch (e) {
      productosRaw = [];
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                  child: pw.Text(ajustes['nombre_negocio'] ?? 'RECIBO',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.Text("NIT: ${ajustes['nit'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
              pw.Text("Dir: ${ajustes['direccion'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
              pw.Divider(thickness: 1),

              // Tabla de productos - Mapeo corregido a las claves correctas
              pw.Table.fromTextArray(
                headers: ['Producto', 'Precio'],
                data: productosRaw.map((p) {
                  // Manejo de seguridad para evitar nulls
                  String nombre = (p['nombre_producto'] ?? p['nombre'] ?? 'Producto').toString();
                  num precio = (p['precio_unitario'] as num?) ?? 0;

                  return [nombre, "\$${precio.toInt()}"];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 7),
                columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
              ),

              pw.Spacer(),

              // Bloque de Totales
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text("Subtotal: \$${subtotal.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                  if (aplicarImpuesto)
                    pw.Text("IVA (${ivaConfigurado.toInt()}%): \$${valorIva.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                  pw.Divider(thickness: 0.5),
                  pw.Text("TOTAL: \$${totalFinal.toInt()}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ]),
              ),
            ],
          );
        },
      ),
    );

    // Imprimir el PDF
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}