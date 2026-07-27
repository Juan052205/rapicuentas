import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'generadorcuentaspantalla.dart';

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

  // Lógica del Anuncio Recompensado que faltaba incorporar
  void _cargarYMostrarAnuncioRecompensado(BuildContext context, Map<String, dynamic> ventaAClonar) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917', // ID de prueba oficial Google
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
                const SnackBar(content: Text("🎉 ¡Ganaste 1 intento de clonación extra!"))
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
              const SnackBar(content: Text("🎁 ¡Intento extra concedido por cortesía!"))
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Historial de Ventas")),
    body: _ventas.isEmpty
        ? const Center(child: Text("No hay ventas registradas aún"))
        : ListView.builder(
      itemCount: _ventas.length,
      itemBuilder: (context, index) {
        final v = _ventas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(v['nombre_empresa']),
            subtitle: Text("Total: \$${v['total']}\nFecha: ${v['fecha']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // BOTÓN REUTILIZAR / CLONAR CON VALIDACIÓN FREEMIUM Y RECOMPENSA
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
                      // Modal limpio con la opción de ver video o hacerse Pro
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("⚠️ Límite de clonaciones alcanzado"),
                          content: const Text(
                              "Has agotado tus 3 intentos gratuitos de clonación.\n\n"
                                  "• Ve un short video para ganar **1 intento extra**.\n"
                                  "• O hazte Pro para clonaciones ilimitadas sin anuncios."
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.orange),
                              onPressed: () {
                                Navigator.pop(c);
                                _cargarYMostrarAnuncioRecompensado(context, v);
                              },
                              child: const Text("Ver Video (+1)"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white
                              ),
                              onPressed: () async {
                                // 1. Activamos el estatus Pro en la base de datos (es_pro = 1)
                                await DatabaseHelper.instance.actualizarEstadoPro(1);

                                if (!context.mounted) return;
                                Navigator.pop(c); // Cerramos el modal de escasez

                                // 2. Feedback visual de éxito
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🚀 ¡Felicidades! Versión Pro activada con éxito. Clonaciones ilimitadas."),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 4),
                                  ),
                                );

                                // Opcional: Si estabas intentando clonar una venta al momento de saltar el muro,
                                // puedes proceder directamente a clonarla ya que ahora es Pro:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GeneradorCuentasPantalla(ventaAClonar: v),
                                  ),
                                );
                              },
                              child: const Text("Hacerme Pro"),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                // BOTÓN PDF
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
                  onPressed: () async => await PdfGenerator.generarFactura(v, false, 0.0),
                ),
                // BOTÓN ELIMINAR
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
                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sí")),
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