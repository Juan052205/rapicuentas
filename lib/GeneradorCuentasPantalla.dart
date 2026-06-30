import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';

class GeneradorCuentasPantalla extends StatefulWidget {
  final Map<String, dynamic>? ventaAClonar;
  const GeneradorCuentasPantalla({super.key, this.ventaAClonar});

  @override
  State<GeneradorCuentasPantalla> createState() => _GeneradorCuentasPantallaState();
}

class _GeneradorCuentasPantallaState extends State<GeneradorCuentasPantalla> {
  bool _aplicarImpuesto = false;
  double _ivaConfigurado = 19.0;
  final List<Map<String, dynamic>> _carrito = [];
  double _total = 0.0;
  String _metodoPago = 'Efectivo';

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
    // Si traemos una venta desde el historial, la cargamos automáticamente
    if (widget.ventaAClonar != null) {
      cargarVentaParaReutilizar(widget.ventaAClonar!);
    }
  }

  Future<void> _cargarAjustes() async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    if (mounted) {
      setState(() => _ivaConfigurado = ajustes['iva_porcentaje'] ?? 19.0);
    }
  }

  void cargarVentaParaReutilizar(Map<String, dynamic> venta) {
    try {
      List<dynamic> productos = jsonDecode(venta['productos_detalle']);
      setState(() {
        _carrito.clear();
        _total = (venta['total'] as num).toDouble();
        _metodoPago = venta['metodo_pago'] ?? 'Efectivo';
        for (var p in productos) {
          _carrito.add({
            'nombre': p['nombre'],
            'cant': p['cant'],
            'total': p['total']
          });
        }
      });
    } catch (e) {
      debugPrint("Error al clonar venta: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Facturación")),
      body: SafeArea(
        child: Column(
          children: [
            // LISTA DE PRODUCTOS
            Expanded(
              child: _carrito.isEmpty
                  ? const Center(child: Text("Carrito vacío"))
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _carrito.length,
                separatorBuilder: (ctx, i) => const Divider(), // <-- Agregado 'const'
                itemBuilder: (c, i) => ListTile(
                  title: Text(_carrito[i]['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)), // <-- Agregado 'const'
                  trailing: Text("\$${_carrito[i]['total']}"),
                ),
              ),
            ),

            // PANEL INFERIOR (Botón y Switch siempre visibles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text("Impuestos (${_ivaConfigurado.toInt()}%)"),
                    value: _aplicarImpuesto,
                    onChanged: (v) => setState(() => _aplicarImpuesto = v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // Creamos el mapa al momento exacto de la impresión
                        Map<String, dynamic> ventaParaPdf = {
                          'total': _total,
                          'productos_detalle': jsonEncode(_carrito),
                          'metodo_pago': _metodoPago
                        };
                        PdfGenerator.generarFactura(ventaParaPdf, _aplicarImpuesto, _ivaConfigurado);
                      },
                      label: const Text("IMPRIMIR FACTURA", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}