import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/producto.dart';

class ProductosPantalla extends StatefulWidget {
  const ProductosPantalla({super.key});

  @override
  State<ProductosPantalla> createState() => _ProductosPantallaState();
}

class _ProductosPantallaState extends State<ProductosPantalla> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final data = await DatabaseHelper.instance.obtenerProductosModelo();
    if (!mounted) return;
    setState(() => _productos = data);
  }

  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text;
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0.0;

    if (nombre.isNotEmpty && precio > 0) {
      final nuevoProducto = Producto(
        nombreProducto: nombre,
        precioUnitario: precio,
      );

      await DatabaseHelper.instance.insertarProductoModelo(nuevoProducto);
      _nombreController.clear();
      _precioController.clear();
      _cargarProductos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Producto guardado exitosamente"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ingresa un nombre y un precio válido mayor a 0"), backgroundColor: Colors.orange),
      );
    }
  }

  void _mostrarFormularioEdicion(Producto producto) {
    final editNombre = TextEditingController(text: producto.nombreProducto);
    final editPrecio = TextEditingController(text: producto.precioUnitario.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editNombre, decoration: const InputDecoration(labelText: "Nombre del Producto")),
            const SizedBox(height: 10),
            TextField(controller: editPrecio, decoration: const InputDecoration(labelText: "Precio Unitario"), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              editNombre.dispose();
              editPrecio.dispose();
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevoPrecio = double.tryParse(editPrecio.text.replaceAll(',', '.')) ?? 0.0;
              if (editNombre.text.isNotEmpty && nuevoPrecio > 0) {
                final productoActualizado = Producto(
                  id: producto.id,
                  nombreProducto: editNombre.text,
                  precioUnitario: nuevoPrecio,
                );

                await DatabaseHelper.instance.actualizarProductoModelo(productoActualizado);

                editNombre.dispose();
                editPrecio.dispose();

                if (!context.mounted) return;
                Navigator.pop(context);
                _cargarProductos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Producto actualizado con éxito"), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Producto"),
        content: const Text("¿Deseas eliminar este producto del inventario?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.eliminarProducto(id);
              if (!context.mounted) return;
              Navigator.pop(context);
              _cargarProductos();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🗑️ Producto eliminado"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Gestión de Productos")),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Agregar Producto o Servicio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                const SizedBox(height: 10),
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre del Producto",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _precioController,
                  decoration: const InputDecoration(
                    labelText: "Precio Unitario (\$)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _guardarProducto,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text("Guardar Producto", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text("Inventario Activo (${_productos.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: _productos.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_outlined, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text("No hay productos creados aún", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _productos.length,
              itemBuilder: (c, i) {
                final prod = _productos[i];
                String nombre = prod.nombreProducto;
                double precio = prod.precioUnitario;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: Colors.green.shade700, size: 20),
                    ),
                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "\$${precio.toStringAsFixed(0)}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blue.shade800),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () => _mostrarFormularioEdicion(prod),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => prod.id != null ? _confirmarEliminar(prod.id!) : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}