import 'package:flutter/material.dart';
import '../play_billing_service.dart';

class ProUpsellModal extends StatelessWidget {
  final String titulo;
  final String mensaje;

  const ProUpsellModal({
    super.key,
    this.titulo = "🚀 Desbloquea Rapicuentas Pro",
    this.mensaje = "Obtén acceso ilimitado a todas las herramientas gerenciales sin anuncios ni restricciones.",
  });

  static void mostrar(BuildContext context, {String? titulo, String? mensaje}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProUpsellModal(
        titulo: titulo ?? "🚀 Desbloquea Rapicuentas Pro",
        mensaje: mensaje ?? "Obtén acceso ilimitado a todas las herramientas gerenciales sin anuncios ni restricciones.",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.workspace_premium, size: 54, color: Colors.amber),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildBeneficioItem(Icons.block, "Sin anuncios publicitarios"),
          _buildBeneficioItem(Icons.all_inclusive, "Clonación ilimitada de facturas"),
          _buildBeneficioItem(Icons.image, "Logotipo personalizado en tus recibos"),
          _buildBeneficioItem(Icons.analytics, "Tablero analítico con métricas avanzadas"),
          _buildBeneficioItem(Icons.style, "Estilos y colores PDF corporativos"),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await PlayBillingService().comprarVersionPro();
              },
              child: const Text("OBTENER VERSIÓN PRO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PlayBillingService().restaurarCompras();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🔄 Solicitud de restauración enviada a Google Play Store"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.restore, size: 14, color: Colors.grey),
            label: const Text("¿Ya compraste Pro? Restablece tu compra aquí", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficioItem(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}