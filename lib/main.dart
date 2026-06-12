import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'configuracion_pantalla.dart';
import 'productos_pantalla.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
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
    const Center(child: Text("Módulo Clientes (Pendiente Stark)")),
    const GeneradorCuentasPantalla(),
    const ProductosPantalla(), // Aquí llamamos a la nueva pantalla
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
  final List<Map<String, dynamic>> _carrito = [];
  double _total = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cargarProductos(); // Se recarga automáticamente al volver a la pestaña
  }

  Future<void> _cargarProductos() async {
    final data = await DatabaseHelper.instance.obtenerProductosActivos();
    if (!mounted) return;
    setState(() => _prods = data);
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      _carrito.add(producto);
      _total += (producto['precio_unitario'] as num).toDouble();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Agregado: ${producto['nombre_producto']}"),
        duration: const Duration(seconds: 1),
      ),
    );
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
            MaterialPageRoute(builder: (_) => const ConfiguracionPantalla()),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: _prods.isEmpty
              ? const Center(child: Text("No hay productos registrados."))
              : ListView.builder(
            itemCount: _prods.length,
            itemBuilder: (context, index) {
              final producto = _prods[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.bakery_dining, color: Colors.orange),
                  title: Text(
                    producto['nombre_producto']?.toString() ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '\$${producto['precio_unitario']?.toString() ?? '0'}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                    onPressed: () => _agregarAlCarrito(producto),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: const Border(top: BorderSide(color: Colors.blue, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL:",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                "\$$_total",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}