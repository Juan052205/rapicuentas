import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProductosPantalla extends StatefulWidget {
  const ProductosPantalla({super.key});

  @override
  State<ProductosPantalla> createState() => _ProductosPantallaState();
}

class _ProductosPantallaState extends State<ProductosPantalla> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();

  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text;
    final precio = double.tryParse(_precioController.text) ?? 0.0;

    if (nombre.isNotEmpty && precio > 0) {
      await DatabaseHelper.instance.insertarProducto({
        'nombre_producto': nombre,
        'precio_unitario': precio,
      });
      _nombreController.clear();
      _precioController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Producto guardado exitosamente")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Gestión de Productos")),
    body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: "Nombre del Producto"),
          ),
          TextField(
            controller: _precioController,
            decoration: const InputDecoration(labelText: "Precio"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _guardarProducto,
            child: const Text("Guardar Producto"),
          ),
        ],
      ),
    ),
  );
}