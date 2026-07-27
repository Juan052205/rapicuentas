import 'dart:convert';
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

  static Future<void> generarFactura(Map<String, dynamic> venta, bool aplicarImpuesto, double ivaConfigurado) async {
    await _gestionarAnuncioYExportar(() async {
      final pdf = pw.Document();
      final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

      int esPro = ajustes['es_pro'] ?? 0;
      String nombreNegocio = ajustes['nombre_negocio'] ?? 'RECIBO';

      double subtotal = (venta['total'] as num?)?.toDouble() ?? 0.0;
      double valorIva = aplicarImpuesto ? (subtotal * (ivaConfigurado / 100)) : 0.0;
      double totalFinal = subtotal + valorIva;

      String tipoDoc = venta['tipo_documento'] ?? 'COMPROBANTE DE VENTA';

      List<dynamic> productosRaw = [];
      try {
        productosRaw = jsonDecode(venta['productos_detalle']);
      } catch (e) {
        productosRaw = [];
      }

      // Agrupación estricta para garantizar que nunca se repita una línea de producto en la factura
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
                pw.Text("NIT: ${ajustes['nit'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
                pw.Text("Dir: ${ajustes['direccion'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
                pw.Divider(thickness: 1),
                pw.Table.fromTextArray(
                  headers: ['Producto', 'Cant', 'Precio'],
                  data: productosProcesados.map((p) {
                    String nombre = p['nombre'].toString();
                    int cant = p['cant'] as int;
                    num totalProd = p['total'] as num;

                    return [nombre, "$cant", "\$${totalProd.toInt()}"];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(0.7),
                    2: const pw.FlexColumnWidth(1),
                  },
                ),
                pw.Spacer(),
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
                if (esPro == 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Center(
                      child: pw.Text(
                        "Generado con Rapicuentas - Descárgala gratis en Play Store",
                        style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey500),
                      ),
                    ),
                  ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
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
  }
}