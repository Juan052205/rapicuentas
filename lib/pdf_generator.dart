// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, const_eval_type_bool_num_string

import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class PdfGenerator {
  static Future<void> generarFactura(Map<String, dynamic> venta) async {
    final pdf = pw.Document();

    // 1. Obtenemos datos de la base de datos
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    final nombreNegocio = ajustes['nombre_negocio'] ?? 'Mi Negocio';
    final nit = ajustes['nit'] ?? 'N/A';
    final direccion = ajustes['direccion'] ?? 'N/A';

    // 2. Procesamiento de datos de productos
    List<dynamic> productosRaw = [];
    try {
      productosRaw = jsonDecode(venta['productos_detalle']);
    } catch (e) {
      productosRaw = [];
    }

    List<List<String>> tablaData = [];
    for (var p in productosRaw) {
      tablaData.add([
        p['nombre'].toString(),
        p['cant'].toString(),
        "\$${(p['precio'] as num).toInt()}",
        "\$${(p['total'] as num).toInt()}"
      ]);
    }

    // 3. Construcción del PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER INTEGRADO CON DATOS Y BRANDING
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(nombreNegocio.toUpperCase(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                        pw.Text("NIT: $nit | DIR: $direccion",
                            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text("FACTURA", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // DETALLES CLIENTE
              pw.Text("CLIENTE: ${venta['nombre_empresa'] ?? 'N/A'}", style: pw.TextStyle(fontSize: 8)),
              pw.Text("FECHA: ${venta['fecha'].toString().substring(0, 10)}", style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),

              // TABLA
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1.5)},
                headers: ['PRODUCTO', 'CANT', 'UNIT', 'TOTAL'],
                data: tablaData,
              ),

              pw.Divider(color: PdfColors.grey300),

              // TOTALES
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("TOTAL: \$${(venta['total'] as num).toInt()}",
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
              ),

              pw.Spacer(),

              // FOOTER
              pw.Center(
                child: pw.Text("Gracias por tu confianza", style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}