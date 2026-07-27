import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';

class PdfGenerator {
  static Future<void> _gestionarAnuncioYExportar(Function onExportar) async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    int esPro = ajustes['es_pro'] ?? 0;

    if (esPro == 1) {
      await onExportar();
      return;
    }

    try {
      final resultadoRed = await InternetAddress.lookup('google.com');
      if (resultadoRed.isEmpty || resultadoRed[0].rawAddress.isEmpty) {
        throw const SocketException('Sin internet');
      }
    } on SocketException catch (_) {
      throw Exception("⚠️ Modo offline detectado. Las cuentas gratuitas requieren conexión a internet para validar la pauta publicitaria. Conéctate a una red o hazte Pro para uso ilimitado offline.");
    }

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              onExportar();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              onExportar();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          onExportar();
        },
      ),
    );
  }

  static Future<void> generarFactura(
      Map<String, dynamic> venta,
      bool aplicarImpuesto,
      double ivaConfigurado,
      {String retencionTipo = 'Ninguna', double retencionPorcentaje = 0.0}
      ) async {
    try {
      await _gestionarAnuncioYExportar(() async {
        final pdf = pw.Document();
        final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

        int esPro = ajustes['es_pro'] ?? 0;
        String nombreNegocio = ajustes['nombre_negocio'] ?? 'RECIBO';
        String resolucionDian = ajustes['resolucion_dian'] ?? '';
        String metodoPago = venta['metodo_pago'] ?? 'Efectivo';

        int consecutivoFactura = await DatabaseHelper.instance.obtenerYIncrementarConsecutivo();
        String numeroFacturaFormateado = "FE-${consecutivoFactura.toString().padLeft(4, '0')}";

        double subtotal = (venta['total'] as num?)?.toDouble() ?? 0.0;
        double valorIva = aplicarImpuesto ? (subtotal * (ivaConfigurado / 100)) : 0.0;
        double valorRetencion = (retencionPorcentaje > 0) ? (subtotal * (retencionPorcentaje / 100)) : 0.0;

        double totalFinal = subtotal + valorIva - valorRetencion;

        String tipoDoc = venta['tipo_documento'] ?? 'COMPROBANTE DE VENTA';
        String observaciones = venta['observaciones'] ?? '';

        List<dynamic> productosRaw = [];
        try {
          productosRaw = jsonDecode(venta['productos_detalle']);
        } catch (e) {
          productosRaw = [];
        }

        Map<String, Map<String, dynamic>> agrupados = {};
        for (var p in productosRaw) {
          String nombre = (p['nombre'] ?? p['nombre_producto'] ?? 'Producto').toString();
          int cant = (p['cant'] as num?)?.toInt() ?? 1;
          double precio = ((p['precio'] ?? p['precio_unitario'] ?? 0) as num).toDouble();
          double totalItem = (p['total'] as num?)?.toDouble() ?? (precio * cant);

          if (agrupados.containsKey(nombre)) {
            agrupados[nombre]!['cant'] += cant;
            agrupados[nombre]!['total'] += totalItem;
          } else {
            agrupados[nombre] = {
              'nombre': nombre,
              'cant': cant,
              'precio': precio > 0 ? precio : (cant > 0 ? totalItem / cant : 0.0),
              'total': totalItem,
            };
          }
        }
        List<Map<String, dynamic>> productosProcesados = agrupados.values.toList();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a6,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                      child: pw.Text(nombreNegocio,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
                  pw.Center(
                      child: pw.Text(tipoDoc,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey700))),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("NIT: ${ajustes['nit'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
                      pw.Text("Factura: $numeroFacturaFormateado", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Text("Dir: ${ajustes['direccion'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
                  pw.Text("Método de Pago: $metodoPago", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Divider(thickness: 1),
                  pw.Table.fromTextArray(
                    headers: const ['Producto', 'Cant', 'Precio'],
                    data: productosProcesados.map((p) {
                      String nombre = p['nombre'].toString();
                      int cant = p['cant'] as int;
                      num totalProd = p['total'] as num;

                      return [nombre, "$cant", "\$${totalProd.toInt()}"];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(0.7),
                      2: pw.FlexColumnWidth(1),
                    },
                  ),
                  if (observaciones.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Observaciones:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                          pw.Text(observaciones, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey800)),
                        ],
                      ),
                    ),
                  pw.Spacer(),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text("Subtotal: \$${subtotal.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                      if (aplicarImpuesto)
                        pw.Text("IVA (${ivaConfigurado.toInt()}%): \$${valorIva.toInt()}", style: const pw.TextStyle(fontSize: 8)),
                      if (retencionPorcentaje > 0)
                        pw.Text("$retencionTipo (${retencionPorcentaje}%): -\$${valorRetencion.toInt()}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700)),
                      pw.Divider(thickness: 0.5),
                      pw.Text("TOTAL: \$${totalFinal.toInt()}",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ]),
                  ),
                  pw.Divider(thickness: 0.5),
                  if (resolucionDian.isNotEmpty)
                    pw.Paragraph(
                      text: "Resolución DIAN No. $resolucionDian",
                      style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                    ),
                  if (esPro == 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Center(
                        child: pw.Text(
                          "Generado con Rapicuentas - Descárgala gratis en Play Store",
                          style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey500),
                        ),
                      ),
                    ),
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text("Gracias por su preferencia", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600)),
                    ),
                  )
                ],
              );
            },
          ),
        );

        await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      });
    } catch (e) {
      debugPrint("Error de exportación: $e");
      rethrow;
    }
  }
}