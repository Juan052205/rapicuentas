import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'formato_cop.dart';

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

  static bool _flagIva(Map<String, dynamic> v) =>
      (v['aplicar_iva'] as num?)?.toInt() == 1;

  static double _ivaPct(Map<String, dynamic> v) =>
      (v['iva_porcentaje'] as num?)?.toDouble() ?? 0.0;

  static String _retTipo(Map<String, dynamic> v) =>
      (v['retencion_tipo'] ?? 'Ninguna').toString();

  static double _retPct(Map<String, dynamic> v) =>
      (v['retencion_porcentaje'] as num?)?.toDouble() ?? 0.0;

  static Future<void> generarFacturaDesdeRegistro(Map<String, dynamic> v) {
    return generarFactura(
      v,
      _flagIva(v),
      _ivaPct(v),
      retencionTipo: _retTipo(v),
      retencionPorcentaje: _retPct(v),
    );
  }

  static Future<void> compartirFacturaPdfDesdeRegistro(Map<String, dynamic> v) {
    return compartirFacturaPdf(
      v,
      _flagIva(v),
      _ivaPct(v),
      retencionTipo: _retTipo(v),
      retencionPorcentaje: _retPct(v),
    );
  }

  /// Construye el PDF sin anuncios ni diálogo del sistema.
  /// Lo usa la vista previa in-app (imprimir + compartir en la misma pantalla).
  static Future<pw.Document> construirDocumentoDesdeVenta(Map<String, dynamic> v) {
    return _construirDocumentoPdf(
      v,
      _flagIva(v),
      _ivaPct(v),
      retencionTipo: _retTipo(v),
      retencionPorcentaje: _retPct(v),
    );
  }

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
        final pdf = await _construirDocumentoPdf(
          venta,
          aplicarImpuesto,
          ivaConfigurado,
          retencionTipo: retencionTipo,
          retencionPorcentaje: retencionPorcentaje,
        );
        await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
        final pdf = await _construirDocumentoPdf(
          venta,
          aplicarImpuesto,
          ivaConfigurado,
          retencionTipo: retencionTipo,
          retencionPorcentaje: retencionPorcentaje,
        );
        final numero = (venta['numero_factura'] ?? 'factura').toString();
        final nombreArchivo = numero.isEmpty ? 'factura_recibo.pdf' : '$numero.pdf';
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: nombreArchivo,
        );
      });
    } catch (e) {
      debugPrint("Error al compartir PDF: $e");
      rethrow;
    }
  }

  /// Muestra el anuncio (si aplica) y luego ejecuta [onListo].
  /// Sirve para abrir la vista previa in-app después de finalizar una venta.
  static Future<void> conAnuncioSiAplica(Future<void> Function() onListo) async {
    await _gestionarAnuncioYExportar(onListo);
  }

  static pw.Widget _filaTotal(String etiqueta, String valor, {bool resaltar = false, PdfColor? color}) {
    final c = color ?? PdfColors.grey800;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            etiqueta,
            style: pw.TextStyle(
              fontSize: resaltar ? 10 : 8,
              fontWeight: resaltar ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: c,
            ),
          ),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: resaltar ? 11 : 8,
              fontWeight: pw.FontWeight.bold,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _encabezadoClasico({
    required pw.MemoryImage? logoImage,
    required String nombreNegocio,
    required Map<String, dynamic> ajustes,
    required PdfColor colorCorporativo,
    required String tipoDoc,
    required String numeroFacturaFormateado,
    required String fechaFormateada,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoImage != null)
          pw.Container(
            width: 50,
            height: 50,
            margin: const pw.EdgeInsets.only(right: 10),
            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                nombreNegocio,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: colorCorporativo,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'NIT: ${ajustes['nit'] ?? 'No definido'}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),
              pw.Text(
                'Dir: ${ajustes['direccion'] ?? 'No definido'}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Container(
          width: 132,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: pw.BoxDecoration(
            color: colorCorporativo,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                tipoDoc,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                numeroFacturaFormateado,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                fechaFormateada,
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _encabezadoModerno({
    required pw.MemoryImage? logoImage,
    required String nombreNegocio,
    required Map<String, dynamic> ajustes,
    required PdfColor colorCorporativo,
    required String tipoDoc,
    required String numeroFacturaFormateado,
    required String fechaFormateada,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: pw.BoxDecoration(
        color: colorCorporativo,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoImage != null)
            pw.Container(
              width: 46,
              height: 46,
              margin: const pw.EdgeInsets.only(right: 10),
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  nombreNegocio,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'NIT: ${ajustes['nit'] ?? 'No definido'}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
                pw.Text(
                  'Dir: ${ajustes['direccion'] ?? 'No definido'}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                tipoDoc,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                numeroFacturaFormateado,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                fechaFormateada,
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _encabezadoElegante({
    required pw.MemoryImage? logoImage,
    required String nombreNegocio,
    required Map<String, dynamic> ajustes,
    required PdfColor colorCorporativo,
    required String tipoDoc,
    required String numeroFacturaFormateado,
    required String fechaFormateada,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 48,
                height: 48,
                margin: const pw.EdgeInsets.only(right: 10),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    nombreNegocio,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: colorCorporativo,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'NIT: ${ajustes['nit'] ?? 'No definido'}  ·  Dir: ${ajustes['direccion'] ?? 'No definido'}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  tipoDoc,
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  numeroFacturaFormateado,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: colorCorporativo,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  fechaFormateada,
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1.6, color: colorCorporativo),
      ],
    );
  }

  static pw.Widget _cajaCliente({
    required int estilo,
    required PdfColor colorCorporativo,
    required String nombreClientePdf,
    required String nitClientePdf,
    required String telClientePdf,
    required String dirClientePdf,
    required String metodoPago,
    required String infoCuentaEspecifica,
  }) {
    final contenido = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CLIENTE',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: colorCorporativo,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          nombreClientePdf,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'NIT/CC: $nitClientePdf${telClientePdf.isNotEmpty ? '    Tel: $telClientePdf' : ''}',
          style: const pw.TextStyle(fontSize: 8),
        ),
        if (dirClientePdf.isNotEmpty)
          pw.Text('Dir: $dirClientePdf', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Pago: $metodoPago$infoCuentaEspecifica',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: colorCorporativo,
          ),
        ),
      ],
    );

    if (estilo == 2) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: contenido,
      );
    }

    if (estilo == 1) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(10, 9, 9, 9),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: colorCorporativo, width: 3),
          ),
          color: PdfColors.grey100,
        ),
        child: contenido,
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: contenido,
    );
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
    String nombreNegocio = (ajustes['nombre_negocio'] ?? '').toString().trim();
    if (nombreNegocio.isEmpty) nombreNegocio = 'RECIBO';
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
    if (estiloTabla < 0 || estiloTabla > 2) estiloTabla = 0;
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

    String numeroGuardado = (venta['numero_factura'] ?? '').toString().trim();
    String numeroFacturaFormateado;
    if (numeroGuardado.isNotEmpty) {
      numeroFacturaFormateado = numeroGuardado;
    } else if (venta['id'] != null) {
      numeroFacturaFormateado = 'REF-${venta['id']}';
    } else {
      int consecutivoFactura = await DatabaseHelper.instance.obtenerConsecutivoActual();
      numeroFacturaFormateado = "$prefijo-${consecutivoFactura.toString().padLeft(4, '0')}";
    }

    double subtotal = (venta['total'] as num?)?.toDouble() ?? 0.0;
    double valorIva = aplicarImpuesto ? (subtotal * (ivaConfigurado / 100)) : 0.0;
    double valorRetencion = (retencionPorcentaje > 0) ? (subtotal * (retencionPorcentaje / 100)) : 0.0;
    double totalFinal = subtotal + valorIva - valorRetencion;

    String tipoDoc = venta['tipo_documento'] ?? 'COMPROBANTE DE VENTA';
    String observaciones = venta['observaciones'] ?? '';
    String fechaFormateada = FormatoCop.fechaCorta(venta['fecha']?.toString() ?? '');
    if (fechaFormateada.trim().isEmpty) {
      fechaFormateada = FormatoCop.fechaCorta(DateTime.now().toString());
    }

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

    pw.Widget encabezado;
    if (estiloTabla == 1) {
      encabezado = _encabezadoModerno(
        logoImage: logoImage,
        nombreNegocio: nombreNegocio,
        ajustes: ajustes,
        colorCorporativo: colorCorporativo,
        tipoDoc: tipoDoc,
        numeroFacturaFormateado: numeroFacturaFormateado,
        fechaFormateada: fechaFormateada,
      );
    } else if (estiloTabla == 2) {
      encabezado = _encabezadoElegante(
        logoImage: logoImage,
        nombreNegocio: nombreNegocio,
        ajustes: ajustes,
        colorCorporativo: colorCorporativo,
        tipoDoc: tipoDoc,
        numeroFacturaFormateado: numeroFacturaFormateado,
        fechaFormateada: fechaFormateada,
      );
    } else {
      encabezado = _encabezadoClasico(
        logoImage: logoImage,
        nombreNegocio: nombreNegocio,
        ajustes: ajustes,
        colorCorporativo: colorCorporativo,
        tipoDoc: tipoDoc,
        numeroFacturaFormateado: numeroFacturaFormateado,
        fechaFormateada: fechaFormateada,
      );
    }

    final PdfColor headerTablaColor = estiloTabla == 2 ? PdfColors.grey200 : colorCorporativo;
    final pw.TextStyle headerTablaStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 8,
      color: estiloTabla == 2 ? colorCorporativo : PdfColors.white,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 22),
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  nombreNegocio,
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: colorCorporativo),
                ),
                pw.Text(
                  '$numeroFacturaFormateado  ·  pág. ${context.pageNumber}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.4, color: PdfColors.grey400),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    esPro == 0
                        ? 'Generado con Rapicuentas  ·  Versión gratuita'
                        : 'Generado con Rapicuentas Pro',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Pág. ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            encabezado,
            pw.SizedBox(height: estiloTabla == 1 ? 14 : 12),
            _cajaCliente(
              estilo: estiloTabla,
              colorCorporativo: colorCorporativo,
              nombreClientePdf: nombreClientePdf,
              nitClientePdf: nitClientePdf,
              telClientePdf: telClientePdf,
              dirClientePdf: dirClientePdf,
              metodoPago: metodoPago,
              infoCuentaEspecifica: infoCuentaEspecifica,
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: const ['Producto', 'Cant', 'V. Unit', 'Total'],
              data: productosProcesados.isEmpty
                  ? [
                ['Sin productos', '-', '-', '-']
              ]
                  : productosProcesados.map((p) {
                String nombre = p['nombre'].toString();
                int cant = p['cant'] as int;
                double pUnit = (p['precio_unitario'] as num).toDouble();
                num totalProd = p['total'] as num;
                return [
                  nombre,
                  '$cant',
                  FormatoCop.pesos(pUnit),
                  FormatoCop.pesos(totalProd),
                ];
              }).toList(),
              headerStyle: headerTablaStyle,
              headerDecoration: pw.BoxDecoration(color: headerTablaColor),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              cellDecoration: (row, col, index) {
                if (estiloTabla == 1) {
                  return const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4)),
                  );
                } else if (estiloTabla == 2) {
                  return const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.3)),
                  );
                } else {
                  return row % 2 == 0
                      ? const pw.BoxDecoration(color: PdfColors.grey200)
                      : const pw.BoxDecoration(color: PdfColors.white);
                }
              },
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(0.6),
                2: pw.FlexColumnWidth(1.1),
                3: pw.FlexColumnWidth(1.1),
              },
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (observaciones.isNotEmpty) ...[
                        pw.Text(
                          'Observaciones',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          observaciones,
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                      if (mediosDisponibles.isNotEmpty) ...[
                        pw.Text(
                          'Datos de pago / transferencia',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: colorCorporativo,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          mediosDisponibles.join('\n'),
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                      if (resolucionDian.isNotEmpty)
                        pw.Text(
                          'Resolución DIAN No. $resolucionDian',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  width: 158,
                  padding: const pw.EdgeInsets.all(9),
                  decoration: estiloTabla == 2
                      ? pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: colorCorporativo, width: 1.6)),
                  )
                      : pw.BoxDecoration(
                    border: pw.Border.all(color: colorCorporativo, width: 0.9),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      _filaTotal('Subtotal', FormatoCop.pesos(subtotal)),
                      if (aplicarImpuesto)
                        _filaTotal('IVA (${ivaConfigurado.toInt()}%)', FormatoCop.pesos(valorIva)),
                      if (retencionPorcentaje > 0)
                        _filaTotal(
                          retencionTipo,
                          FormatoCop.pesos(-valorRetencion),
                          color: PdfColors.red700,
                        ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Divider(color: colorCorporativo, thickness: 0.8),
                      ),
                      _filaTotal(
                        'TOTAL',
                        FormatoCop.pesos(totalFinal),
                        resaltar: true,
                        color: colorCorporativo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Gracias por su preferencia',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}