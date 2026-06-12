import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'configuracion_pantalla.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
    const FormularioClientesPantalla(),
    const GeneradorCuentasPantalla(),
    const CatatogoProductosPantalla(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _pantallas[_indiceActual],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _indiceActual,
      onDestinationSelected: (int index) => setState(() => _indiceActual = index),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
        NavigationDestination(icon: Icon(Icons.add_circle), label: 'Nueva Cuenta'),
        NavigationDestination(icon: Icon(Icons.bakery_dining), label: 'Productos'),
      ],
    ),
  );
}

// --- PANTALLA CLIENTES ---
class FormularioClientesPantalla extends StatefulWidget {
  const FormularioClientesPantalla({super.key});
  @override
  State<FormularioClientesPantalla> createState() => _FormularioClientesPantallaState();
}

class _FormularioClientesPantallaState extends State<FormularioClientesPantalla> {
  final _nombre = TextEditingController();
  final _id = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Registrar Cliente")),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _nombre, decoration: const InputDecoration(labelText: "Nombre")),
      TextField(controller: _id, decoration: const InputDecoration(labelText: "NIT/CC")),
      ElevatedButton(onPressed: () async {
        await DatabaseHelper.instance.insertarCliente({'nombre_empresa': _nombre.text, 'identificacion': _id.text});
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(const SnackBar(content: Text("Cliente Guardado")));
      }, child: const Text("Guardar"))
    ])),
  );
}

// --- PANTALLA PRODUCTOS ---
class CatatogoProductosPantalla extends StatefulWidget {
  const CatatogoProductosPantalla({super.key});
  @override
  State<CatatogoProductosPantalla> createState() => _CatatogoProductosPantallaState();
}

class _CatatogoProductosPantallaState extends State<CatatogoProductosPantalla> {
  final _nombre = TextEditingController();
  final _precio = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Catálogo")),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _nombre, decoration: const InputDecoration(labelText: "Producto")),
      TextField(controller: _precio, decoration: const InputDecoration(labelText: "Precio")),
      ElevatedButton(onPressed: () async {
        await DatabaseHelper.instance.insertarProducto({'nombre_producto': _nombre.text, 'precio_unitario': double.parse(_precio.text)});
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(const SnackBar(content: Text("Producto Registrado")));
      }, child: const Text("Registrar"))
    ])),
  );
}

// --- GENERADOR CUENTAS ---
class GeneradorCuentasPantalla extends StatefulWidget {
  const GeneradorCuentasPantalla({super.key});
  @override
  State<GeneradorCuentasPantalla> createState() => _GeneradorCuentasPantallaState();
}

class _GeneradorCuentasPantallaState extends State<GeneradorCuentasPantalla> {
  final List<Map<String, dynamic>> _articulosAgregados = [];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Nueva Cuenta"), actions: [
      IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionPantalla()))),
      IconButton(icon: const Icon(Icons.folder_open), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialCuentasPantalla()))),
    ]),
    body: ListView.builder(
        itemCount: _articulosAgregados.length,
        itemBuilder: (c, i) => ListTile(title: Text(_articulosAgregados[i]['nombre_producto']))
    ),
  );
}

// --- HISTORIAL ---
class HistorialCuentasPantalla extends StatefulWidget {
  const HistorialCuentasPantalla({super.key});
  @override
  State<HistorialCuentasPantalla> createState() => _HistorialCuentasPantallaState();
}

class _HistorialCuentasPantallaState extends State<HistorialCuentasPantalla> {
  List<Map<String, dynamic>> _cuentas = [];

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final d = await DatabaseHelper.instance.obtenerHistorialCuentas();
    if (!mounted) return;
    setState(() => _cuentas = d);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Historial")),
    body: ListView.builder(itemCount: _cuentas.length, itemBuilder: (c, i) => ListTile(
      title: Text(_cuentas[i]['numero_documento']),
      trailing: IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), onPressed: () async {
        final det = await DatabaseHelper.instance.obtenerDetallesCuenta(_cuentas[i]['id']);
        final pag = await DatabaseHelper.instance.obtenerDatosPago();
        if (!mounted) return;
        await PdfGenerator.generarFacturaPDF(_cuentas[i], det, pag);
      }),
    )),
  );
}