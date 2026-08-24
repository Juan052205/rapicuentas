import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';

class PdfGenerator {
  static const List<PdfColor> paletaPdfColores = [
    PdfColors.blue800,
    PdfColors.indigo,
    PdfColors.green800,
    PdfColors.teal,
    PdfColors.red800,
    PdfColors.purple,
    PdfColors.orange800,
    PdfColors.grey800,
    PdfColors.brown,
    PdfColors.cyan800,
  ];

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

    final String adUnitId = Platform.isAndroid
        ? 'ca-app-pub-7567540983279751/3518002746'
        : 'ca-app-pub-7567540983279751/2551621612';

    InterstitialAd.load(
      adUnitId: adUnitId,
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
        final pdf = await _construirDocumentoPdf(venta, aplicarImpuesto, ivaConfigurado, retencionTipo: retencionTipo, retencionPorcentaje: retencionPorcentaje);
        await Printing.layoutPdf(onLayout: (format) async => pdf.save());
        // Incremento atómico post-compilación exitosa
        await DatabaseHelper.instance.incrementarConsecutivo();
      });
    } catch (e) {
      debugPrint("Error de exportación: $e");
      rethrow;
    }
  }

  static Future<void> compartirFacturaPdf(
      Map<String, dynamic> venta,
      bool aplicarImpuesto,
      double ivaConfigurado,
      {String retencionTipo = 'Ninguna', double retencionPorcentaje = 0.0}
      ) async {
    try {
      await _gestionarAnuncioYExportar(() async {
        final pdf = await _construirDocumentoPdf(venta, aplicarImpuesto, ivaConfigurado, retencionTipo: retencionTipo, retencionPorcentaje: retencionPorcentaje);
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'factura_recibo.pdf',
        );
      });
    } catch (e) {
      debugPrint("Error al compartir PDF: $e");
      rethrow;
    }
  }

  static Future<pw.Document> _construirDocumentoPdf(
      Map<String, dynamic> venta,
      bool aplicarImpuesto,
      double ivaConfigurado,
      {String retencionTipo = 'Ninguna', double retencionPorcentaje = 0.0}
      ) async {
    final pdf = pw.Document();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

    int esPro = ajustes['es_pro'] ?? 0;
    String nombreNegocio = ajustes['nombre_negocio'] ?? 'RECIBO';
    String resolucionDian = ajustes['resolucion_dian'] ?? '';
    String metodoPago = venta['metodo_pago'] ?? 'Efectivo';
    String logoPath = ajustes['logo_path'] ?? '';
    String prefijo = (ajustes['prefijo_factura'] ?? 'FE').toString().toUpperCase();

    String nequi = ajustes['nequi'] ?? '';
    String daviplata = ajustes['daviplata'] ?? '';
    String cuentaAhorros = ajustes['cuenta_ahorros'] ?? '';

    String infoCuentaEspecifica = '';
    if (metodoPago.contains('Nequi') && nequi.isNotEmpty) {
      infoCuentaEspecifica = " - N° $nequi";
    } else if (metodoPago.contains('Daviplata') && daviplata.isNotEmpty) {
      infoCuentaEspecifica = " - N° $daviplata";
    } else if ((metodoPago.contains('Cuenta') || metodoPago.contains('Bancaria')) && cuentaAhorros.isNotEmpty) {
      infoCuentaEspecifica = " - N° $cuentaAhorros";
    }

    Map<String, dynamic>? clienteInfo;
    if (venta['cliente_id'] != null) {
      final db = await DatabaseHelper.instance.database;
      final cliRes = await db.query('clientes', where: 'id = ?', whereArgs: [venta['cliente_id']]);
      if (cliRes.isNotEmpty) clienteInfo = cliRes.first;
    }
    String nombreClientePdf = clienteInfo?['nombre_empresa'] ?? venta['nombre_empresa'] ?? 'Consumidor Final';
    String nitClientePdf = clienteInfo?['identificacion'] ?? 'N/A';
    String telClientePdf = clienteInfo?['telefono'] ?? '';
    String dirClientePdf = clienteInfo?['direccion'] ?? '';

    int colorIndex = (ajustes['pdf_color_index'] as num?)?.toInt() ?? 0;
    int estiloTabla = (ajustes['pdf_estilo_tabla'] as num?)?.toInt() ?? 0;
    PdfColor colorCorporativo = paletaPdfColores[colorIndex.clamp(0, paletaPdfColores.length - 1)];

    pw.MemoryImage? logoImage;
    if (esPro == 1 && logoPath.isNotEmpty && File(logoPath).existsSync()) {
      try {
        final bytes = File(logoPath).readAsBytesSync();
        logoImage = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint("Error al cargar logo: $e");
      }
    }

    int consecutivoFactura = await DatabaseHelper.instance.obtenerConsecutivoActual();
    String numeroFacturaFormateado = "$prefijo-${consecutivoFactura.toString().padLeft(4, '0')}";

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
      double precioUnitario = ((p['precio'] ?? p['precio_unitario'] ?? 0) as num).toDouble();
      double totalItem = (p['total'] as num?)?.toDouble() ?? (precioUnitario * cant);

      if (agrupados.containsKey(nombre)) {
        agrupados[nombre]!['cant'] += cant;
        agrupados[nombre]!['total'] += totalItem;
      } else {
        agrupados[nombre] = {
          'nombre': nombre,
          'cant': cant,
          'precio_unitario': precioUnitario > 0 ? precioUnitario : (cant > 0 ? totalItem / cant : 0.0),
          'total': totalItem,
        };
      }
    }
    List<Map<String, dynamic>> productosProcesados = agrupados.values.toList();

    List<String> mediosDisponibles = [];
    if (nequi.isNotEmpty) mediosDisponibles.add("Nequi: $nequi");
    if (daviplata.isNotEmpty) mediosDisponibles.add("Daviplata: $daviplata");
    if (cuentaAhorros.isNotEmpty) mediosDisponibles.add("Cta Ahorros: $cuentaAhorros");

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 35,
                      height: 35,
                      child: pw.Image(logoImage),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(nombreNegocio,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: colorCorporativo)),
                        pw.Text(tipoDoc,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("NIT: ${ajustes['nit'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
                  pw.Text("Factura: $numeroFacturaFormateado", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Text("Dir Negocio: ${ajustes['direccion'] ?? 'No definido'}", style: const pw.TextStyle(fontSize: 7)),
              pw.Divider(thickness: 0.5),

              pw.Text("CLIENTE: $nombreClientePdf", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("NIT/CC: $nitClientePdf", style: const pw.TextStyle(fontSize: 6.5)),
                  if (telClientePdf.isNotEmpty)
                    pw.Text("Tel: $telClientePdf", style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
              if (dirClientePdf.isNotEmpty)
                pw.Text("Dir: $dirClientePdf", style: const pw.TextStyle(fontSize: 6.5)),

              pw.Text("Método de Pago: $metodoPago$infoCuentaEspecifica", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: colorCorporativo)),
              pw.Divider(thickness: 1, color: colorCorporativo),

              pw.Table.fromTextArray(
                headers: const ['Producto', 'Cant', 'V. Unit', 'Total'],
                data: productosProcesados.map((p) {
                  String nombre = p['nombre'].toString();
                  int cant = p['cant'] as int;
                  double pUnit = (p['precio_unitario'] as num).toDouble();
                  num totalProd = p['total'] as num;

                  return [nombre, "$cant", "\$${pUnit.toInt()}", "\$${totalProd.toInt()}"];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: colorCorporativo),
                cellStyle: const pw.TextStyle(fontSize: 6.5),
                cellDecoration: (row, col, index) {
                  if (estiloTabla == 0) {
                    return row % 2 == 0
                        ? const pw.BoxDecoration(color: PdfColors.grey200)
                        : const pw.BoxDecoration(color: PdfColors.white);
                  } else {
                    return const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                    );
                  }
                },
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.8),
                  1: pw.FlexColumnWidth(0.6),
                  2: pw.FlexColumnWidth(1.1),
                  3: pw.FlexColumnWidth(1.1),
                },
              ),

              if (observaciones.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Observaciones:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5)),
                      pw.Text(observaciones, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey800)),
                    ],
                  ),
                ),
              if (mediosDisponibles.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Datos de Pago / Transferencia:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6, color: colorCorporativo)),
                      pw.Text(mediosDisponibles.join(" | "), style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey800)),
                    ],
                  ),
                ),
              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text("Subtotal: \$${subtotal.toInt()}", style: const pw.TextStyle(fontSize: 7.5)),
                  if (aplicarImpuesto)
                    pw.Text("IVA (${ivaConfigurado.toInt()}%): \$${valorIva.toInt()}", style: const pw.TextStyle(fontSize: 7.5)),
                  if (retencionPorcentaje > 0)
                    pw.Text("$retencionTipo (${retencionPorcentaje}%): -\$${valorRetencion.toInt()}", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.red700)),
                  pw.Divider(thickness: 0.5),
                  pw.Text("TOTAL: \$${totalFinal.toInt()}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: colorCorporativo)),
                ]),
              ),
              pw.Divider(thickness: 0.5),
              if (resolucionDian.isNotEmpty)
                pw.Paragraph(
                  text: "Resolución DIAN No. $resolucionDian",
                  style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
                ),
              if (esPro == 0)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Center(
                    child: pw.Text(
                      "Generado con Rapicuentas - Versión Gratuita",
                      style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600),
                    ),
                  ),
                ),
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text("Gracias por su preferencia", style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600)),
                ),
              )
            ],
          );
        },
      ),
    );

    return pdf;
  }
}