import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'generadorcuentaspantalla.dart'; // <--- ESTO ES LO QUE TE FALTABA

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
                // BOTÓN REUTILIZAR
                IconButton(
                  icon: const Icon(Icons.copy_all, color: Colors.blue),
                  onPressed: () {
                    // Al navegar, enviamos el registro 'v' completo
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GeneradorCuentasPantalla(ventaAClonar: v),
                      ),
                    );
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