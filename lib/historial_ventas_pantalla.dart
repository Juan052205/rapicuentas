import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';

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
        final v = _ventas[index]; // Definimos 'v' aquí
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.green),
            title: Text("Cliente: ${v['nombre_empresa']}"),
            subtitle: Text("Fecha: ${v['fecha'].toString().substring(0, 16)}\nProd: ${v['productos_detalle']}"),
            // Ponemos el PDF y el Total juntos en el trailing usando una Row
            trailing: Row(
              mainAxisSize: MainAxisSize.min, // Esto es clave para que no ocupe todo el ancho
              children: [
                Text("\$${v['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => PdfGenerator.generarFactura(v),
                ),
              ],
            ),
          ),
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _cargarHistorial,
      child: const Icon(Icons.refresh),
    ),
  );
}