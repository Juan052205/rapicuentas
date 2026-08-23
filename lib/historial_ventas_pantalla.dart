import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'main.dart';
import 'play_billing_service.dart';

class HistorialVentasPantalla extends StatefulWidget {
  const HistorialVentasPantalla({super.key});

  @override
  State<HistorialVentasPantalla> createState() => _HistorialVentasPantallaState();
}

class _HistorialVentasPantallaState extends State<HistorialVentasPantalla> {
  List<Map<String, dynamic>> _ventas = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final data = await DatabaseHelper.instance.obtenerHistorialVentas();
    if (!mounted) return;
    setState(() => _ventas = data);
  }

  Future<void> _mostrarModuloAnalitico(BuildContext context) async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    int esPro = ajustes['es_pro'] ?? 0;

    double totalVentasGlobal = _ventas.fold(0.0, (sum, item) => sum + ((item['total'] as num?)?.toDouble() ?? 0.0));
    int cantidadVentas = _ventas.length;
    double promedioVenta = cantidadVentas > 0 ? totalVentasGlobal / cantidadVentas : 0.0;

    Map<String, double> metodosPagoConteo = {};
    Map<String, int> productosTop = {};

    if (esPro == 1) {
      for (var v in _ventas) {
        String metodo = v['metodo_pago'] ?? 'Efectivo';
        double val = (v['total'] as num?)?.toDouble() ?? 0.0;
        metodosPagoConteo[metodo] = (metodosPagoConteo[metodo] ?? 0.0) + val;

        try {
          if (v['productos_detalle'] != null) {
            List<dynamic> prods = jsonDecode(v['productos_detalle']);
            for (var p in prods) {
              String nombre = (p['nombre'] ?? p['nombre_producto'] ?? 'Producto').toString();
              int cant = (p['cant'] as num?)?.toInt() ?? 1;
              productosTop[nombre] = (productosTop[nombre] ?? 0) + cant;
            }
          }
        } catch (_) {}
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: esPro == 1 ? Colors.blue : Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                esPro == 1 ? "Tablero Analitico Pro" : "Resumen de Ventas",
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
                Text("Total Facturado: \$${totalVentasGlobal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text("Comprobantes Emitidos: $cantidadVentas"),
                Text("Ticket Promedio: \$${promedioVenta.toStringAsFixed(0)}"),
                const Divider(height: 20),

                if (esPro == 1) ...[
                  const Text("📊 Desglose por Metodo de Pago:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                  const SizedBox(height: 6),
                  if (metodosPagoConteo.isEmpty)
                    const Text("Sin datos suficientes", style: TextStyle(fontSize: 11, color: Colors.grey))
                  else
                    ...metodosPagoConteo.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text("• ${e.key}: \$${e.value.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12)),
                    )),
                  const SizedBox(height: 12),
                  const Text("🏆 Top Productos Vendidos:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                  const SizedBox(height: 6),
                  if (productosTop.isEmpty)
                    const Text("Sin datos suficientes", style: TextStyle(fontSize: 11, color: Colors.grey))
                  else
                    ...productosTop.entries.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text("• ${e.key} (${e.value} unidades)", style: const TextStyle(fontSize: 12)),
                    )),
                ] else ...[
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
                        Text("🔒 Funcionalidad Exclusiva Pro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900)),
                        const SizedBox(height: 4),
                        const Text("Desbloquea el desglose por metodos de pago, top de productos mas vendidos y analiticas avanzadas haciendote Pro.", style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (esPro == 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              onPressed: () async {
                Navigator.pop(c);
                await PlayBillingService().comprarVersionPro();
              },
              child: const Text("Desbloquear Pro"),
            ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cerrar")),
        ],
      ),
    );
  }

  Future<void> _manejarCompartirPdf(Map<String, dynamic> v) async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    int esPro = ajustes['es_pro'] ?? 0;

    if (esPro == 1) {
      await _compartirFacturaPdfDirecto(v);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("📢 Compartir Comprobante"),
          content: const Text(
              "Las cuentas gratuitas pueden compartir documentos viendo un breve video o haciendose Pro para envio inmediato sin anuncios."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("Cancelar"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
              onPressed: () {
                Navigator.pop(c);
                _cargarYMostrarAnuncioRecompensadoParaCompartir(context, v);
              },
              child: const Text("Ver Video y Compartir"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(c);
                await PlayBillingService().comprarVersionPro();
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
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
            },
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 ¡Video completado! Abriendo opciones de compartir..."))
            );
            await _compartirFacturaPdfDirecto(venta);
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🎁 ¡Acceso concedido por cortesia!"))
          );
          _compartirFacturaPdfDirecto(venta);
        },
      ),
    );
  }

  Future<void> _compartirFacturaPdfDirecto(Map<String, dynamic> v) async {
    try {
      await PdfGenerator.compartirFacturaPdf(v, false, 0.0);
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
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
            },
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            await DatabaseHelper.instance.otorgarIntentosExtraPorAd();

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🎉 ¡Ganaste 1 intento de clonacion extra!"))
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
              const SnackBar(content: Text("🎁 ¡Intento extra concedido por cortesia!"))
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Historial de Ventas"),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: "Modulo Analitico",
          onPressed: () => _mostrarModuloAnalitico(context),
        ),
      ],
    ),
    body: _ventas.isEmpty
        ? const Center(child: Text("No hay ventas registradas aun"))
        : ListView.builder(
      itemCount: _ventas.length,
      itemBuilder: (context, index) {
        final v = _ventas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(v['nombre_empresa'] ?? 'Cliente'),
            subtitle: Text("Total: \$${v['total']}\nFecha:${v['fecha']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.teal),
                  tooltip: "Enviar PDF",
                  onPressed: () => _manejarCompartirPdf(v),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_all, color: Colors.blue),
                  onPressed: () async {
                    bool permitido = await DatabaseHelper.instance.intentarConsumirClonacion();

                    if (!context.mounted) return;

                    if (permitido) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GeneradorCuentasPantalla(ventaAClonar: v),
                        ),
                      );
                    } else {
                      bool puedeVerVideo = await DatabaseHelper.instance.puedeVerVideoRecompensa();

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("⚠️ Limite de clonaciones alcanzado"),
                          content: Text(
                              puedeVerVideo
                                  ? "Has agotado tus 3 intentos gratuitos de clonacion.\n\n"
                                  "• Ve 1 unico video para ganar **1 intento extra**.\n"
                                  "• O hazte Pro para clonaciones ilimitadas sin anuncios."
                                  : "Has agotado tus intentos gratuitos y tu video de bonificacion unico.\n\n"
                                  "• Hazte Pro para clonaciones ilimitadas sin anuncios."
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("Cancelar"),
                            ),
                            if (puedeVerVideo)
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                onPressed: () async {
                                  Navigator.pop(c);
                                  await DatabaseHelper.instance.marcarVideoComoUsado();
                                  _cargarYMostrarAnuncioRecompensado(context, v);
                                },
                                child: const Text("Ver Video Unico (+1)"),
                              ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white
                              ),
                              onPressed: () async {
                                Navigator.pop(c);
                                await PlayBillingService().comprarVersionPro();
                              },
                              child: const Text("Hacerme Pro"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
                  onPressed: () async {
                    try {
                      await PdfGenerator.generarFactura(v, false, 0.0);
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
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool? confirm = await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Eliminar"),
                        content: const Text("¿Deseas borrar esta venta?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No")),
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Si")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await DatabaseHelper.instance.eliminarVenta(v['id']);
                      _cargarHistorial();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}