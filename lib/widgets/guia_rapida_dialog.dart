import 'package:flutter/material.dart';

/// Guía rápida adaptable a cualquier tamaño de pantalla.
/// Usar [mostrarGuiaRapidaRapicuentas] para abrirla como diálogo.
class GuiaRapidaDialog extends StatelessWidget {
  const GuiaRapidaDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height * 0.88;
    final maxW = media.size.width;
    final estrecho = maxW < 360;
    final corto = media.size.height < 640;
    final pad = corto ? 14.0 : 20.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: estrecho ? 10 : 16,
        vertical: corto ? 12 : 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: maxH,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Guía Rápida Rapicuentas",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Optimiza tu negocio y factura con nivel gerencial usando estas secciones clave:",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _item(
                          icon: Icons.people_outline,
                          titulo: "1. Clientes",
                          descripcion: "Registra la base de tus compradores o empresas frecuentes.",
                        ),
                        _item(
                          icon: Icons.inventory_2_outlined,
                          titulo: "2. Productos",
                          descripcion: "Administra tu catálogo de productos y precios unitarios.",
                        ),
                        _item(
                          icon: Icons.receipt_long_outlined,
                          titulo: "3. Facturar",
                          descripcion: "Selecciona cliente, productos y genera tu recibo PDF de inmediato.",
                          destacado: true,
                        ),
                        _item(
                          icon: Icons.history,
                          titulo: "4. Historial",
                          descripcion: "Administra, comparte o clona ventas pasadas.\n• Tip Pro: Toca 📊 para ver métricas avanzadas.",
                          destacado: true,
                        ),
                        _item(
                          icon: Icons.settings_outlined,
                          titulo: "5. Ajustes",
                          descripcion: "Configura datos de tu negocio, métodos de pago (Nequi/Daviplata) y diseño de recibos.",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "¡Entendido, a facturar!",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String titulo,
    required String descripcion,
    bool destacado = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destacado ? Colors.blue.shade50.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: destacado ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(descripcion, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> mostrarGuiaRapidaRapicuentas(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const GuiaRapidaDialog(),
  );
}