import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'formato_cop.dart';
import 'models/producto.dart';
import 'widgets/pro_upsell_modal.dart';

class ProductosPantalla extends StatefulWidget {
  const ProductosPantalla({super.key});

  @override
  State<ProductosPantalla> createState() => ProductosPantallaState();
}

class ProductosPantallaState extends State<ProductosPantalla> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _busquedaController = TextEditingController();
  List<Producto> _productos = [];
  int? _esPro = DatabaseHelper.instance.esProEnMemoria;
  String _busqueda = '';

  bool get tieneDatosSinGuardar {
    return _nombreController.text.trim().isNotEmpty ||
        _precioController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    final data = await DatabaseHelper.instance.obtenerProductosModelo();
    final datosPago = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _productos = data;
      _esPro = datosPago['es_pro'] ?? 0;
    });
  }

  List<Producto> get _productosFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _productos;
    return _productos.where((p) => p.nombreProducto.toLowerCase().contains(q)).toList();
  }

  void _ocultarTeclado() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _guardarProducto() async {
    _ocultarTeclado();
    await Future.delayed(const Duration(milliseconds: 80));

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
          content: Text("Producto guardado exitosamente"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa un nombre y un precio válido mayor a 0"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
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
              FocusManager.instance.primaryFocus?.unfocus();
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
                  const SnackBar(
                    content: Text("Producto actualizado con éxito"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
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
                const SnackBar(content: Text("Producto eliminado"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPro() {
    if (_esPro != 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Center(
        child: InkWell(
          onTap: () => ProUpsellModal.mostrar(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.orange.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 15),
                SizedBox(width: 4),
                Text(
                  "PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaProducto(Producto prod) {
    final nombre = prod.nombreProducto;
    final precio = prod.precioUnitario;

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
              FormatoCop.pesos(precio),
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
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _productosFiltrados;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Gestión de Productos"),
        actions: [_buildBotonPro()],
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
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
                      textInputAction: TextInputAction.next,
                      onTapOutside: (_) => _ocultarTeclado(),
                      decoration: const InputDecoration(
                        labelText: "Nombre del Producto",
                        hintText: "Ej: Libra de arroz",
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
                        hintText: "Ej: 2500",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _guardarProducto(),
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
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "Inventario Activo (${filtrados.length}${_busqueda.isEmpty ? '' : ' de ${_productos.length}'})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _busquedaController,
                      textInputAction: TextInputAction.search,
                      onTapOutside: (_) => _ocultarTeclado(),
                      decoration: InputDecoration(
                        hintText: "Buscar producto...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _busqueda.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _busquedaController.clear();
                            _ocultarTeclado();
                            setState(() => _busqueda = '');
                          },
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                  ],
                ),
              ),
            ),
            if (filtrados.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          _productos.isEmpty ? "No hay productos creados aún" : "Sin resultados para la búsqueda",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (c, i) => _tarjetaProducto(filtrados[i]),
                    childCount: filtrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}