import 'package:flutter/material.dart';

class ComparacionProWidget extends StatelessWidget {
  const ComparacionProWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Comparativa de Planes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              border: TableBorder.all(color: Colors.grey.shade200, width: 1),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(padding: EdgeInsets.all(8.0), child: Text("Función", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text("Gratis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                    Padding(padding: EdgeInsets.all(8.0), child: Text("Pro 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue), textAlign: TextAlign.center)),
                  ],
                ),
                _buildFila("Generación PDF", "Limitado/Ads", "Ilimitado"),
                _buildFila("Clonación de Ventas", "3 Intentos", "Ilimitado"),
                _buildFila("Logotipo en Recibos", "❌", "✅"),
                _buildFila("Colores PDF", "Estándar", "10 Colores"),
                _buildFila("Métricas y Análisis", "Básico", "Avanzado"),
                _buildFila("Publicidad", "Con Anuncios", "Sin Anuncios"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildFila(String funcion, String gratis, String pro) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(funcion, style: const TextStyle(fontSize: 11))),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(gratis, style: TextStyle(fontSize: 11, color: Colors.grey.shade700), textAlign: TextAlign.center)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(pro, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue), textAlign: TextAlign.center)),
      ],
    );
  }
}