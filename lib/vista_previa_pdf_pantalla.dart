import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'pdf_generator.dart';

/// Vista previa in-app del comprobante con botones de imprimir y compartir.
/// Se usa después de finalizar una venta para no forzar un segundo anuncio.
class VistaPreviaPdfPantalla extends StatelessWidget {
  final Map<String, dynamic> venta;
  final String? mensajeCabecera;

  const VistaPreviaPdfPantalla({
    super.key,
    required this.venta,
    this.mensajeCabecera,
  });

  String get _nombreArchivo {
    final n = (venta['numero_factura'] ?? '').toString().trim();
    if (n.isEmpty) return 'factura_recibo.pdf';
    return '$n.pdf';
  }

  String get _titulo {
    final n = (venta['numero_factura'] ?? '').toString().trim();
    if (n.isEmpty) return 'Comprobante';
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulo),
      ),
      body: Column(
        children: [
          if (mensajeCabecera != null && mensajeCabecera!.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.green.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mensajeCabecera!,
                      style: TextStyle(fontSize: 13, color: Colors.green.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Usa el ícono de compartir para enviarlo por WhatsApp, correo o cualquier app. El de impresora sirve para imprimir o guardar PDF.",
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.3),
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (PdfPageFormat format) async {
                final doc = await PdfGenerator.construirDocumentoDesdeVenta(venta);
                return doc.save();
              },
              initialPageFormat: PdfPageFormat.a5,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: _nombreArchivo,
            ),
          ),
        ],
      ),
    );
  }
}