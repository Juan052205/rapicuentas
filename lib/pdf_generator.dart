import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generarFactura(Map<String, dynamic> venta) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6, // Formato tipo ticket
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("ALMOJÁBANAS Y AREPAS EL TÍO", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text("Cliente: ${venta['nombre_empresa']}"),
              pw.Text("Fecha: ${venta['fecha'].toString().substring(0, 16)}"),
              pw.SizedBox(height: 10),
              pw.Text("DETALLE:"),
              pw.Text(venta['productos_detalle']),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text("TOTAL: \$${venta['total']}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Gracias por su compra!", textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    // Lanzar la vista previa para imprimir o compartir
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}