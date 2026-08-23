import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'clientes_pantalla.dart';
import 'productos_pantalla.dart';
import 'historial_ventas_pantalla.dart';
import 'ajustes_pantalla.dart';
import 'pdf_generator.dart';
import 'personalizacion_pdf_pantalla.dart';
import 'play_billing_service.dart'; // 📌 Importación del servicio de Google Play Billing

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const SplashScreen(),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    DatabaseHelper.instance.database;
    await Future.delayed(const Duration(milliseconds: 4000));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NavegacionPrincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.35),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 58),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Rapicuentas",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Facturación y Gestión Profesional",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;
  bool _mostrarBienvenidaOverlay = false;

  final List<Widget> _pantallas = [
    const ClientesPantalla(),
    const ProductosPantalla(),
    const GeneradorCuentasPantalla(),
    const HistorialVentasPantalla(),
    const PersonalizacionPdfPantalla(),
  ];

  @override
  void initState() {
    super.initState();
    _verificarPrimerInicioUnicaVez();

    // 🚀 Inicializamos Google Play Billing globalmente al arrancar la app
    PlayBillingService().inicializar(() {
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 ¡Versión Pro activada con éxito a través de Google Play!"),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  Future<void> _verificarPrimerInicioUnicaVez() async {
    bool mostrar = await DatabaseHelper.instance.debeMostrarBienvenida();
    if (mostrar) {
      await DatabaseHelper.instance.marcarBienvenidaVista();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _mostrarBienvenidaOverlay = true);
      });
    }
  }

  void _cerrarBienvenida() {
    setState(() => _mostrarBienvenidaOverlay = false);
  }

  void _mostrarGuiaAyuda() {
    setState(() => _mostrarBienvenidaOverlay = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pantallas[_indiceActual],
          if (_mostrarBienvenidaOverlay)
            AnimatedOpacity(
              opacity: _mostrarBienvenidaOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Guía Rápida Rapicuentas",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                              onPressed: _cerrarBienvenida,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Optimiza tu negocio y factura con nivel gerencial usando estas secciones clave:",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        _buildItemGuia(
                          icon: Icons.people_outline,
                          titulo: "1. Clientes",
                          descripcion: "Registra la base de tus compradores o empresas frecuentes.",
                        ),
                        _buildItemGuia(
                          icon: Icons.inventory_2_outlined,
                          titulo: "2. Prod",
                          descripcion: "Administra tu catálogo de productos y precios unitarios.",
                        ),
                        _buildItemGuia(
                          icon: Icons.receipt_long_outlined,
                          titulo: "3. Cuenta (Nueva Factura)",
                          descripcion: "Selecciona cliente, productos y genera tu recibo PDF.\n• Tip Pro: Toca el engranaje ⚙️ arriba a la derecha para configurar tu NIT y logotipo.",
                          destacado: true,
                        ),
                        _buildItemGuia(
                          icon: Icons.history,
                          titulo: "4. Historial",
                          descripcion: "Administra, comparte o clona ventas pasadas.\n• Tip Pro: Toca el icono de analíticas 📊 para ver tu resumen de ventas y productos top.",
                          destacado: true,
                        ),
                        _buildItemGuia(
                          icon: Icons.palette_outlined,
                          titulo: "5. Diseño",
                          descripcion: "Personaliza los colores corporativos y estilos de tus recibos PDF.",
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _cerrarBienvenida,
                            child: const Text("¡Entendido, a facturar!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        tooltip: "Guía e Instrucciones",
        onPressed: _mostrarGuiaAyuda,
        child: const Icon(Icons.help_outline),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) =>
            setState(() => _indiceActual = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.bakery_dining), label: 'Prod'),
          NavigationDestination(icon: Icon(Icons.add_circle), label: 'Cuenta'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.palette), label: 'Diseño'),
        ],
      ),
    );
  }

  Widget _buildItemGuia({required IconData icon, required String titulo, required String descripcion, bool destacado = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destacado ? Colors.blue.shade50.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: destacado ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(descripcion, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeneradorCuentasPantalla extends StatefulWidget {
  final Map<String, dynamic>? ventaAClonar;
  const GeneradorCuentasPantalla({super.key, this.ventaAClonar});

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

  String _tipoDocumentoSeleccionado = 'COMPROBANTE DE VENTA';
  final List<String> _tiposDocumento = ['COMPROBANTE DE VENTA', 'COTIZACIÓN', 'RECIBO DE CAJA'];

  bool _aplicarIva = false;
  double _ivaPorcentaje = 19.0;
  String _retencionSeleccionada = 'Ninguna';
  double _retencionPorcentaje = 0.0;

  final Map<String, double> _opcionesRetenciones = {
    'Ninguna': 0.0,
    'ReteFuente (4%)': 4.0,
    'ReteICA (1%)': 1.0,
    'ReteIVA (15%)': 15.0,
  };

  final TextEditingController _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosYClonacion();
  }

  void _editarPrecioTemporalProducto(int index) {
    final producto = _prods[index];
    final controller = TextEditingController(text: producto['precio_unitario'].toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text("Cambiar precio: ${producto['nombre_producto']}"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Nuevo Precio Unitario",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              String textoPrecio = controller.text.trim().replaceAll(',', '.');
              double nuevoPrecio = double.tryParse(textoPrecio) ?? (producto['precio_unitario'] as num).toDouble();

              setState(() {
                _prods[index]['precio_unitario'] = nuevoPrecio;
              });

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Precio actualizado para esta factura"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarDatosYClonacion() async {
    final p = await DatabaseHelper.instance.obtenerProductosActivos();
    final c = await DatabaseHelper.instance.obtenerClientes();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

    if (!mounted) return;
    setState(() {
      _prods = p.map((e) => Map<String, dynamic>.from(e)).toList();
      _clientes = c;
      _ivaPorcentaje = (ajustes['iva_porcentaje'] as num?)?.toDouble() ?? 19.0;

      if (widget.ventaAClonar != null) {
        final venta = widget.ventaAClonar!;
        _metodoSeleccionado = venta['metodo_pago'] ?? 'Efectivo';
        _tipoDocumentoSeleccionado = venta['tipo_documento'] ?? 'COMPROBANTE DE VENTA';
        _observacionesController.text = venta['observaciones'] ?? '';

        try {
          _clienteSeleccionado = _clientes.firstWhere((cli) => cli['id'] == venta['cliente_id']);
        } catch (_) {}

        if (venta['productos_detalle'] != null) {
          try {
            final List<dynamic> productosDecodificados = jsonDecode(venta['productos_detalle']);
            _total = 0.0;
            _carrito.clear();

            for (var item in productosDecodificados) {
              String nombre = (item['nombre'] ?? item['nombre_producto'] ?? 'Producto').toString();
              int cantidad = (item['cant'] as num?)?.toInt() ?? 1;
              double precio = ((item['precio'] ?? item['precio_unitario'] ?? 0) as num).toDouble();

              if (item.containsKey('total') && precio == 0 && cantidad > 0) {
                precio = (item['total'] as num).toDouble() / cantidad;
              }

              for (int i = 0; i < cantidad; i++) {
                _carrito.add({
                  'nombre_producto': nombre,
                  'precio_unitario': precio,
                });
                _total += precio;
              }
            }
          } catch (e) {
            debugPrint("Error al decodificar clonación: $e");
          }
        }
      }
    });
  }

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
        'tipo_documento': _tipoDocumentoSeleccionado,
        'observaciones': _observacionesController.text,
      };

      await PdfGenerator.generarFactura(
          nuevaVenta,
          _aplicarIva,
          _ivaPorcentaje,
          retencionTipo: _retencionSeleccionada,
          retencionPorcentaje: _retencionPorcentaje
      );

      await DatabaseHelper.instance.insertarVenta(nuevaVenta);

      setState(() {
        _carrito.clear();
        _total = 0.0;
        _clienteSeleccionado = null;
        _metodoSeleccionado = 'Efectivo';
        _tipoDocumentoSeleccionado = 'COMPROBANTE DE VENTA';
        _observacionesController.clear();
        _aplicarIva = false;
        _retencionSeleccionada = 'Ninguna';
        _retencionPorcentaje = 0.0;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Venta registrada y generada")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text("Nueva Cuenta"),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: "Ajustes del Negocio (NIT, Nombre, Logotipo)",
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AjustesScreen())),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: "Tipo Doc.", border: OutlineInputBorder()),
                          value: _tipoDocumentoSeleccionado,
                          items: _tiposDocumento
                              .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ))
                              .toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _tiposDocumento.map<Widget>((String item) {
                              return Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                          onChanged: (val) => setState(() => _tipoDocumentoSeleccionado = val!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: "Pago", border: OutlineInputBorder()),
                          value: _metodoSeleccionado,
                          items: _metodos
                              .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          ))
                              .toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _metodos.map<Widget>((String item) {
                              return Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                          onChanged: (val) => setState(() => _metodoSeleccionado = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text("Configuración de Impuestos y Retenciones", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    leading: const Icon(Icons.calculate, color: Colors.blue),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: Text("Aplicar IVA (${_ivaPorcentaje.toInt()}%)"),
                              value: _aplicarIva,
                              onChanged: (val) => setState(() => _aplicarIva = val),
                            ),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Retención Aplicable",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              value: _retencionSeleccionada,
                              items: _opcionesRetenciones.keys.map((String key) {
                                return DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(key, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (String? nuevoValor) {
                                setState(() {
                                  _retencionSeleccionada = nuevoValor!;
                                  _retencionPorcentaje = _opcionesRetenciones[nuevoValor] ?? 0.0;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacionesController,
                    decoration: const InputDecoration(
                        labelText: "Observaciones / Términos (Opcional)",
                        border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  "Selección de Productos",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                ),
                const Spacer(),
                Text(
                  "Toca + para agregar",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          Expanded(
            flex: 5,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              itemCount: _prods.length,
              itemBuilder: (c, i) {
                final producto = _prods[i];
                final cantidadSeleccionada = _contarEnCarrito(producto['nombre_producto']);

                return Card(
                  child: ListTile(
                    title: Text(producto['nombre_producto']),
                    subtitle: InkWell(
                      onTap: () => _editarPrecioTemporalProducto(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "\$${producto['precio_unitario']}",
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit, size: 12, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 70, 20),
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
    ),
  );
}