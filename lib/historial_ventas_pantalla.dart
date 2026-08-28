import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'formato_cop.dart';
import 'GeneradorCuentasPantalla.dart';
import 'widgets/pro_upsell_modal.dart';

class HistorialVentasPantalla extends StatefulWidget {
  final bool visible;
  const HistorialVentasPantalla({super.key, this.visible = true});

  @override
  State<HistorialVentasPantalla> createState() => _HistorialVentasPantallaState();
}

class _HistorialVentasPantallaState extends State<HistorialVentasPantalla> {
  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _ventasFiltradas = [];
  int? _esPro = DatabaseHelper.instance.esProEnMemoria;
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  @override
  void didUpdateWidget(HistorialVentasPantalla oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _cargarHistorial();
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarHistorial() async {
    final data = await DatabaseHelper.instance.obtenerHistorialVentas();
    final datosPago = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _ventas = data;
      _esPro = datosPago['es_pro'] ?? 0;
      _aplicarFiltro(_busquedaController.text);
    });
  }

  void _aplicarFiltro(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) {
      _ventasFiltradas = List.from(_ventas);
      return;
    }
    _ventasFiltradas = _ventas.where((v) {
      final nombre = (v['nombre_empresa'] ?? '').toString().toLowerCase();
      final numero = (v['numero_factura'] ?? '').toString().toLowerCase();
      final metodo = (v['metodo_pago'] ?? '').toString().toLowerCase();
      return nombre.contains(query) || numero.contains(query) || metodo.contains(query);
    }).toList();
  }

  Future<void> _mostrarModuloAnalitico(BuildContext context) async {
    final ajustes = await DatabaseHelper.instance.obtenerAjustes();
    bool esPro = ajustes.esPro == 1;

    double totalVentasGlobal = _ventas.fold(
      0.0,
          (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0.0),
    );
    int cantidadVentas = _ventas.length;
    double promedioVenta =
    cantidadVentas > 0 ? totalVentasGlobal / cantidadVentas : 0.0;

    final ahora = DateTime.now();
    final inicioMesActual = DateTime(ahora.year, ahora.month, 1);
    final inicioMesAnterior = DateTime(ahora.year, ahora.month - 1, 1);
    final finMesAnterior = inicioMesActual.subtract(const Duration(seconds: 1));

    double totalMesActual = 0;
    int cantMesActual = 0;
    double totalMesAnterior = 0;
    int cantMesAnterior = 0;

    Map<String, double> metodosPagoConteo = {};
    Map<String, int> productosTop = {};

    for (var v in _ventas) {
      final totalVenta = (v['total'] as num?)?.toDouble() ?? 0.0;
      final fecha = DateTime.tryParse(v['fecha']?.toString() ?? '');

      if (fecha != null) {
        if (!fecha.isBefore(inicioMesActual)) {
          totalMesActual += totalVenta;
          cantMesActual++;
        } else if (!fecha.isBefore(inicioMesAnterior) &&
            !fecha.isAfter(finMesAnterior)) {
          totalMesAnterior += totalVenta;
          cantMesAnterior++;
        }
      }

      if (esPro) {
        final metodo = v['metodo_pago'] ?? 'Efectivo';
        metodosPagoConteo[metodo] =
            (metodosPagoConteo[metodo] ?? 0.0) + totalVenta;

        try {
          if (v['productos_detalle'] != null) {
            final List<dynamic> prods = jsonDecode(v['productos_detalle']);
            for (var p in prods) {
              final nombre =
              (p['nombre'] ?? p['nombre_producto'] ?? 'Producto').toString();
              final cant = (p['cant'] as num?)?.toInt() ?? 1;
              productosTop[nombre] = (productosTop[nombre] ?? 0) + cant;
            }
          }
        } catch (_) {}
      }
    }

    const meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final nombreMesActual = meses[ahora.month];
    final mesAntRef = DateTime(ahora.year, ahora.month - 1, 1);
    final nombreMesAnterior = meses[mesAntRef.month];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: esPro ? Colors.blue : Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                esPro ? "Tablero Analítico Pro" : "Resumen de Ventas",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Facturado: ${FormatoCop.pesos(totalVentasGlobal)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text("Comprobantes Emitidos: $cantidadVentas"),
                Text("Ticket Promedio: ${FormatoCop.pesos(promedioVenta)}"),
                const Divider(height: 20),
                Text(
                  "$nombreMesActual: ${FormatoCop.pesos(totalMesActual)} · $cantMesActual facturas",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  "$nombreMesAnterior: ${FormatoCop.pesos(totalMesAnterior)} · $cantMesAnterior facturas",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (esPro) ...[
                  const Divider(height: 20),
                  const Text(
                    "Desglose por Método de Pago:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (metodosPagoConteo.isEmpty)
                    const Text(
                      "Sin datos suficientes",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  else
                    ...metodosPagoConteo.entries.map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          "• ${e.key}: ${FormatoCop.pesos(e.value)}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    "Top Productos Vendidos:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (productosTop.isEmpty)
                    const Text(
                      "Sin datos suficientes",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  else
                    ...(() {
                      final ranking = productosTop.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));
                      return ranking.take(5).map(
                            (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            "• ${e.key} (${e.value} unidades)",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    })(),
                ] else ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Funcionalidad Exclusiva Pro",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Desbloquea el desglose por métodos de pago y el top de productos más vendidos activando la versión Pro.",
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (!esPro)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              onPressed: () {
                Navigator.pop(c);
                ProUpsellModal.mostrar(
                  context,
                  titulo: "Métricas Avanzadas Pro",
                  mensaje:
                  "Accede al desglose detallado de formas de pago y productos estrella para tomar decisiones gerenciales.",
                );
              },
              child: const Text("Desbloquear Pro"),
            ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Future<void> _manejarCompartirPdf(Map<String, dynamic> v) async {
    final ajustes = await DatabaseHelper.instance.obtenerAjustes();
    if (ajustes.esPro == 1) {
      await _compartirFacturaPdfDirecto(v);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Compartir Comprobante"),
          content: const Text(
              "Las cuentas gratuitas pueden compartir documentos viendo un breve video o haciéndose Pro para envío inmediato sin anuncios."
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(c);
                _cargarYMostrarAnuncioRecompensadoParaCompartir(context, v);
              },
              child: const Text("Ver Video y Compartir"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(c);
                ProUpsellModal.mostrar(context);
              },
              child: const Text("Hacerme Pro"),
            ),
          ],
        ),
      );
    }
  }

  void _cargarYMostrarAnuncioRecompensadoParaCompartir(BuildContext context, Map<String, dynamic> venta) {
    final String adUnitId = Platform.isAndroid
        ? 'ca-app-pub-7567540983279751/3019309291'
        : 'ca-app-pub-7567540983279751/5142804555';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) => ad.dispose(),
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Video completado. Elimina los anuncios pasándote a Pro."),
                backgroundColor: Colors.teal.shade800,
                duration: const Duration(seconds: 4),
                showCloseIcon: true,
                closeIconColor: Colors.amber,
                action: SnackBarAction(
                  label: "VER PRO",
                  textColor: Colors.amber,
                  onPressed: () => ProUpsellModal.mostrar(context),
                ),
              ),
            );
            await _compartirFacturaPdfDirecto(venta);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Acceso concedido por cortesía"))
          );
          _compartirFacturaPdfDirecto(venta);
        },
      ),
    );
  }

  Future<void> _compartirFacturaPdfDirecto(Map<String, dynamic> v) async {
    try {
      await PdfGenerator.compartirFacturaPdfDesdeRegistro(v);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _cargarYMostrarAnuncioRecompensado(BuildContext context, Map<String, dynamic> ventaAClonar) {
    final String adUnitId = Platform.isAndroid
        ? 'ca-app-pub-7567540983279751/3019309291'
        : 'ca-app-pub-7567540983279751/5142804555';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) => ad.dispose(),
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            await DatabaseHelper.instance.otorgarIntentosExtraPorAd();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Clonación concedida. Elimina los anuncios pasándote a Pro."),
                backgroundColor: Colors.green.shade800,
                duration: const Duration(seconds: 4),
                showCloseIcon: true,
                closeIconColor: Colors.amber,
                action: SnackBarAction(
                  label: "VER PRO",
                  textColor: Colors.amber,
                  onPressed: () => ProUpsellModal.mostrar(context),
                ),
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GeneradorCuentasPantalla(ventaAClonar: ventaAClonar),
              ),
            );
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          DatabaseHelper.instance.otorgarIntentosExtraPorAd();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Intento extra concedido por cortesía"))
          );
        },
      ),
    );
  }

  Future<void> _ejecutarClonacion(Map<String, dynamic> v) async {
    bool permitido = await DatabaseHelper.instance.intentarConsumirClonacion();

    if (!mounted) return;

    if (permitido) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GeneradorCuentasPantalla(ventaAClonar: v),
        ),
      );
    } else {
      bool puedeVerVideo = await DatabaseHelper.instance.puedeVerVideoRecompensa();

      if (!mounted) return;

      if (!puedeVerVideo) {
        ProUpsellModal.mostrar(
          context,
          titulo: "Límite de clonaciones alcanzado",
          mensaje: "Has agotado tus intentos gratuitos y la bonificación por video. Obtén Rapicuentas Pro para clonar de forma ilimitada.",
        );
      } else {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Límite de clonaciones alcanzado"),
            content: const Text(
                "Has agotado tus 3 intentos gratuitos de clonación.\n\n"
                    "• Ve 1 único video para ganar 1 intento extra.\n"
                    "• O hazte Pro para clonaciones ilimitadas sin anuncios."
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () async {
                  Navigator.pop(c);
                  await DatabaseHelper.instance.marcarVideoComoUsado();
                  _cargarYMostrarAnuncioRecompensado(context, v);
                },
                child: const Text("Ver Video Único (+1)"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(c);
                  ProUpsellModal.mostrar(context);
                },
                child: const Text("Hacerme Pro"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _eliminarVenta(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Eliminar Venta"),
        content: const Text("¿Deseas borrar esta venta del historial de forma permanente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Sí, Eliminar"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.eliminarVenta(id);
      _cargarHistorial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Venta eliminada"), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildBotonPro() {
    if (_esPro != 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Center(
        child: InkWell(
          onTap: () => ProUpsellModal.mostrar(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.orange.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 15),
                SizedBox(width: 4),
                Text(
                  "PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _etiquetaNumero(Map<String, dynamic> v) {
    final n = (v['numero_factura'] ?? '').toString().trim();
    if (n.isNotEmpty) return n;
    return 'REF-${v['id']}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: AppBar(
      title: const Text("Historial de Ventas"),
      actions: [
        _buildBotonPro(),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: "Módulo Analítico",
          onPressed: () => _mostrarModuloAnalitico(context),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              hintText: "Buscar por cliente, número o pago...",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _busquedaController.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _busquedaController.clear();
                  setState(() => _aplicarFiltro(''));
                },
              ),
              border: const OutlineInputBorder(),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _aplicarFiltro(v)),
          ),
        ),
        Expanded(
          child: _ventas.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 54, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text("No hay ventas registradas aún", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          )
              : _ventasFiltradas.isEmpty
              ? Center(
            child: Text("Sin resultados", style: TextStyle(color: Colors.grey.shade600)),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _ventasFiltradas.length,
            itemBuilder: (context, index) {
              final v = _ventasFiltradas[index];
              final numero = _etiquetaNumero(v);
              final metodo = (v['metodo_pago'] ?? 'Efectivo').toString();
              final fecha = FormatoCop.fechaCorta(v['fecha']?.toString() ?? '');
              final total = FormatoCop.pesos((v['total'] as num?) ?? 0);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade800,
                    child: const Icon(Icons.receipt, size: 20),
                  ),
                  title: Text(
                    v['nombre_empresa'] ?? 'Consumidor Final',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    "$numero  ·  $metodo\nTotal: $total  ·  $fecha",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
                        tooltip: "Ver / Imprimir PDF",
                        onPressed: () async {
                          try {
                            await PdfGenerator.generarFacturaDesdeRegistro(v);
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: Colors.redAccent,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.teal),
                        tooltip: "Enviar PDF",
                        onPressed: () => _manejarCompartirPdf(v),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'clonar') {
                            _ejecutarClonacion(v);
                          } else if (value == 'eliminar') {
                            _eliminarVenta(v['id']);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(
                            value: 'clonar',
                            child: Row(
                              children: [
                                Icon(Icons.copy_all, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Clonar Factura", style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'eliminar',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Eliminar", style: TextStyle(fontSize: 13, color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}