import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'configuracion_pantalla.dart';
import 'clientes_pantalla.dart';
import 'productos_pantalla.dart';

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

  // Recargar datos cada vez que entramos a la pestaña
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        const SnackBar(content: Text("⚠️ Por favor, selecciona un cliente primero")),
      );
      return;
    }
    setState(() {
      _carrito.add(producto);
      _total += (producto['precio_unitario'] as num).toDouble();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Nueva Cuenta"),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionPantalla())),
        ),
      ],
    ),
    body: Column(
      children: [
        // SELECCIÓN DE CLIENTE (PROTOCOLO STARK)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade100,
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
                labelText: "Seleccionar Cliente",
                border: OutlineInputBorder()
            ),
            // Usamos el ID del cliente (int) en lugar de todo el objeto Map
            value: _clienteSeleccionado?['id'],
            items: _clientes.map((c) {
              return DropdownMenuItem<int>(
                value: c['id'] as int, // Usamos el ID como valor único
                child: Text(c['nombre_empresa']?.toString() ?? 'Sin nombre'),
              );
            }).toList(),
            onChanged: (int? nuevoId) {
              setState(() {
                // Buscamos el cliente completo en la lista usando el ID
                _clienteSeleccionado = _clientes.firstWhere(
                        (c) => c['id'] == nuevoId
                );
              });
            },
          ),
        ),
        Expanded(
          child: _prods.isEmpty
              ? const Center(child: Text("No hay productos disponibles"))
              : ListView.builder(
            itemCount: _prods.length,
            itemBuilder: (context, index) {
              final p = _prods[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.bakery_dining, color: Colors.orange),
                  title: Text(p['nombre_producto'] ?? ''),
                  subtitle: Text("\$${p['precio_unitario']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    onPressed: () => _agregarAlCarrito(p),
                  ),
                ),
              );
            },
          ),
        ),
        // TOTALIZADOR
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CLIENTE: ${_clienteSeleccionado?['nombre_empresa'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("TOTAL: \$$_total", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
      ],
    ),
  );
}