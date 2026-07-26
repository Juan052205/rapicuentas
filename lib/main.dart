import 'package:flutter/material.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'clientes_pantalla.dart';
import 'productos_pantalla.dart';
import 'historial_ventas_pantalla.dart';
import 'ajustes_pantalla.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const NavegacionPrincipal(),
  );
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 1;
  final List<Widget> _pantallas = [
    const ClientesPantalla(),
    const GeneradorCuentasPantalla(),
    const ProductosPantalla(),
    const HistorialVentasPantalla(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pantallas[_indiceActual],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _indiceActual,
      onDestinationSelected: (int index) =>
          setState(() => _indiceActual = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
        NavigationDestination(icon: Icon(Icons.add_circle), label: 'Cuenta'),
        NavigationDestination(icon: Icon(Icons.bakery_dining), label: 'Prod'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
      ],
    ),
  );
}

class GeneradorCuentasPantalla extends StatefulWidget {
  const GeneradorCuentasPantalla({super.key});

  @override
  State<GeneradorCuentasPantalla> createState() => _GeneradorCuentasPantallaState();
}

class _GeneradorCuentasPantallaState extends State<GeneradorCuentasPantalla> {
  List<Map<String, dynamic>> _prods = [];
  List<Map<String, dynamic>> _clientes = [];
  final List<Map<String, dynamic>> _carrito = [];
  Map<String, dynamic>? _clienteSeleccionado;
  double _total = 0.0;

  String _metodoSeleccionado = 'Efectivo';
  final List<String> _metodos = ['Efectivo', 'Nequi', 'Daviplata', 'Cuenta Bancaria'];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final p = await DatabaseHelper.instance.obtenerProductosActivos();
    final c = await DatabaseHelper.instance.obtenerClientes();
    if (!mounted) return;
    setState(() {
      _prods = p;
      _clientes = c;
    });
  }

  // Cuenta cuántas veces está un producto en el carrito
  int _contarEnCarrito(String nombreProducto) {
    return _carrito.where((item) => item['nombre_producto'] == nombreProducto).length;
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Selecciona un cliente primero")));
      return;
    }
    setState(() {
      _carrito.add({
        'nombre_producto': producto['nombre_producto'],
        'precio_unitario': (producto['precio_unitario'] as num),
      });
      _total += (producto['precio_unitario'] as num).toDouble();
    });
  }

  void _quitarDelCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) return;

    final index = _carrito.indexWhere((item) => item['nombre_producto'] == producto['nombre_producto']);
    if (index != -1) {
      setState(() {
        _carrito.removeAt(index);
        _total -= (producto['precio_unitario'] as num).toDouble();
        if (_total < 0) _total = 0.0;
      });
    }
  }

  Future<void> _finalizarVenta() async {
    if (_clienteSeleccionado == null || _carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Carrito vacío o cliente no seleccionado")));
      return;
    }

    final Map<String, Map<String, dynamic>> resumen = {};
    for (var p in _carrito) {
      String nombre = p['nombre_producto'];
      double precio = (p['precio_unitario'] as num).toDouble();
      if (resumen.containsKey(nombre)) {
        resumen[nombre]!['cant'] += 1;
        resumen[nombre]!['total'] = (resumen[nombre]!['cant'] as int) * precio;
      } else {
        resumen[nombre] = {
          'nombre': nombre,
          'cant': 1,
          'precio': precio,
          'total': precio
        };
      }
    }

    String jsonProductos = jsonEncode(resumen.values.toList());

    try {
      final nuevaVenta = {
        'cliente_id': _clienteSeleccionado!['id'],
        'total': _total,
        'fecha': DateTime.now().toString(),
        'productos_detalle': jsonProductos,
        'metodo_pago': _metodoSeleccionado,
      };

      await DatabaseHelper.instance.insertarVenta(nuevaVenta);

      setState(() {
        _carrito.clear();
        _total = 0.0;
        _clienteSeleccionado = null;
        _metodoSeleccionado = 'Efectivo';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Venta registrada con éxito")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al guardar: $e")));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Nueva Cuenta"),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AjustesScreen())),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: "Cliente", border: OutlineInputBorder()),
                  value: _clienteSeleccionado?['id'],
                  items: _clientes
                      .map((c) => DropdownMenuItem<int>(
                    value: c['id'] as int,
                    child: Text(c['nombre_empresa'] ?? ''),
                  ))
                      .toList(),
                  onChanged: (int? nuevoId) => setState(() =>
                  _clienteSeleccionado = _clientes
                      .firstWhere((c) => c['id'] == nuevoId)),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: "Pago", border: OutlineInputBorder()),
                  isExpanded: true,
                  value: _metodoSeleccionado,
                  items: _metodos
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => _metodoSeleccionado = val!),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _prods.length,
            itemBuilder: (c, i) {
              final producto = _prods[i];
              final cantidadSeleccionada = _contarEnCarrito(producto['nombre_producto']);

              return Card(
                child: ListTile(
                  title: Text(producto['nombre_producto']),
                  subtitle: Text("\$${producto['precio_unitario']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cantidadSeleccionada > 0) ...[
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _quitarDelCarrito(producto),
                        ),
                        Text(
                          '$cantidadSeleccionada',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        onPressed: () => _agregarAlCarrito(producto),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: \$$_total",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: _finalizarVenta,
                icon: const Icon(Icons.check_circle),
                label: const Text("Finalizar"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}