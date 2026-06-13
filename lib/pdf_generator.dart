// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, const_eval_type_bool_num_string

import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class PdfGenerator {
  static Future<void> generarFactura(Map<String, dynamic> venta) async {
    final pdf = pw.Document();

    // Obtenemos los ajustes de forma dinámica
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    final nombreNegocio = ajustes['nombre_negocio'] ?? 'Mi Negocio';

    // Decodificamos el JSON
    final List<dynamic> productos = jsonDecode(venta['productos_detalle']);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // CABECERA PREMIUM (CON BRANDING)
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey900,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      nombreNegocio.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    // Simulación de Marca de Agua / Logo
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.white)),
                      child: pw.Text("EL TÍO", style: pw.TextStyle(color: PdfColors.white, fontSize: 8)),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Text("CLIENTE: ${venta['nombre_empresa']}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text("FECHA: ${venta['fecha'].toString().split('.')[0]}", style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
              pw.Divider(),

              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey700),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headers: ['ITEM', 'CANT', 'UNIT', 'TOTAL'],
                data: productos.map((p) => [
                  p['nombre'].toString(),
                  p['cant'].toString(),
                  "\$${p['precio'].toStringAsFixed(0)}",
                  "\$${p['total'].toStringAsFixed(0)}"
                ]).toList(),
              ),

              pw.Spacer(),

              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TOTAL A PAGAR:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text("\$${venta['total'].toStringAsFixed(0)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}