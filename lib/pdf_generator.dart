import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generarFacturaPDF(Map<String, dynamic> cuenta, List<Map<String, dynamic>> detalles, Map<String, dynamic>? pago) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(children: [
        pw.Text("Cuenta de Cobro", style: pw.TextStyle(fontSize: 25)),
        pw.Divider(),
        ...detalles.map((d) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("${d['producto']} x${d['cantidad']}"),
          pw.Text("\$${d['subtotal']}"),
        ])),
        pw.Spacer(),
        pw.Text("Pago: ${pago?['nombre_banco'] ?? 'No configurado'} - ${pago?['numero_cuenta'] ?? ''}")
      ]);
    }));
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}