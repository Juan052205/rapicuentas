import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'main.dart'; // O el archivo donde esté GeneradorCuentasPantalla
import 'play_integrity_service.dart';

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

  void _cargarYMostrarAnuncioRecompensado(BuildContext context, Map<String, dynamic> ventaAClonar) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
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
            title: Text(v['nombre_empresa'] ?? 'Cliente'),
            subtitle: Text("Total: \$${v['total']}\nFecha:${v['fecha']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      // Verificamos si el usuario aún tiene disponible su video único de bonificación
                      bool puedeVerVideo = await DatabaseHelper.instance.puedeVerVideoRecompensa();

                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text("⚠️ Límite de clonaciones alcanzado"),
                          content: Text(
                              puedeVerVideo
                                  ? "Has agotado tus 3 intentos gratuitos de clonación.\n\n"
                                  "• Ve 1 único video para ganar **1 intento extra**.\n"
                                  "• O hazte Pro para clonaciones ilimitadas sin anuncios."
                                  : "Has agotado tus intentos gratuitos y tu video de bonificación único.\n\n"
                                  "• Hazte Pro para clonaciones ilimitadas sin anuncios."
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("Cancelar"),
                            ),
                            // Mostramos el botón del video SOLO si no lo ha usado
                            if (puedeVerVideo)
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                onPressed: () async {
                                  Navigator.pop(c);
                                  await DatabaseHelper.instance.marcarVideoComoUsado();
                                  _cargarYMostrarAnuncioRecompensado(context, v);
                                },
                                child: const Text("Ver Video Único (+1)"),
                              ),
                            // Botón de activación Pro con Google Play Integrity
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white
                              ),
                              onPressed: () async {
                                bool esLegitimo = await PlayIntegrityService.verificarLicenciaYPlayStore();

                                if (!context.mounted) return;

                                if (!esLegitimo) {
                                  Navigator.pop(c);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("❌ Verificación de Play Integrity fallida. No se pudo confirmar la licencia oficial."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                await DatabaseHelper.instance.actualizarEstadoPro(1);

                                if (!context.mounted) return;
                                Navigator.pop(c);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🚀 ¡Felicidades! Versión Pro verificada y activada con éxito."),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 4),
                                  ),
                                );

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