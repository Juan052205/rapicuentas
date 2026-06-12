import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'clientes_pantalla.dart';
import 'productos_pantalla.dart';
import 'historial_ventas_pantalla.dart';

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
    const HistorialVentasPantalla(), // <--- Nueva pantalla agregada
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pantallas[_indiceActual],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _indiceActual,
      onDestinationSelected: (int index) => setState(() => _indiceActual = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
        NavigationDestination(icon: Icon(Icons.add_circle), label: 'Cuenta'),
        NavigationDestination(icon: Icon(Icons.bakery_dining), label: 'Productos'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historial'), // <--- Nuevo icono
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

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Selecciona un cliente primero")));
      return;
    }
    setState(() {
      _carrito.add(producto);
      _total += (producto['precio_unitario'] as num).toDouble();
    });
  }

  Future<void> _finalizarVenta() async {
    if (_clienteSeleccionado == null || _carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Carrito vacío o cliente no seleccionado")));
      return;
    }

    final nuevaVenta = {
      'cliente_id': _clienteSeleccionado!['id'],
      'total': _total,
      'fecha': DateTime.now().toString(),
      'productos_detalle':
      _carrito.map((p) => p['nombre_producto']).join(", "),
    };

    await DatabaseHelper.instance.insertarVenta(nuevaVenta);

    setState(() {
      _carrito.clear();
      _total = 0.0;
      _clienteSeleccionado = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Venta finalizada correctamente")));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Nueva Cuenta")),
    body: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          // ignore: deprecated_member_use
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
                labelText: "Seleccionar Cliente",
                border: OutlineInputBorder()),
            value: _clienteSeleccionado?['id'],
            items: _clientes
                .map((c) => DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Text(c['nombre_empresa'] ?? ''),
            ))
                .toList(),
            onChanged: (int? nuevoId) => setState(() => _clienteSeleccionado =
                _clientes.firstWhere((c) => c['id'] == nuevoId)),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _prods.length,
            itemBuilder: (c, i) => Card(
              child: ListTile(
                title: Text(_prods[i]['nombre_producto']),
                subtitle: Text("\$${_prods[i]['precio_unitario']}"),
                trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: () => _agregarAlCarrito(_prods[i])),
              ),
            ),
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