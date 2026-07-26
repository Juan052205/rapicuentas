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
  List<Map<String, dynamic>> _prods = [];
  List<Map<String, dynamic>> _clientes = [];
  final List<Map<String, dynamic>> _carrito = [];
  Map<String, dynamic>? _clienteSeleccionado;

  bool _aplicarImpuesto = false;
  double _ivaConfigurado = 0.0;
  double _subtotal = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final p = await DatabaseHelper.instance.obtenerProductosActivos();
    final c = await DatabaseHelper.instance.obtenerClientes();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();

    if (!mounted) return;

    setState(() {
      _prods = p;
      _clientes = c;
      _ivaConfigurado = (ajustes['iva_porcentaje'] as num?)?.toDouble() ?? 0.0;
    });

    if (widget.ventaAClonar != null) {
      _cargarVentaParaReutilizar(widget.ventaAClonar!);
    }
  }

  void _cargarVentaParaReutilizar(Map<String, dynamic> venta) {
    try {
      List<dynamic> productos = jsonDecode(venta['productos_detalle']);

      Map<String, dynamic>? clienteEncontrado;
      if (venta.containsKey('cliente_id') && _clientes.isNotEmpty) {
        try {
          clienteEncontrado = _clientes.firstWhere((c) => c['id'] == venta['cliente_id']);
        } catch (_) {
          clienteEncontrado = null;
        }
      }

      setState(() {
        _carrito.clear();
        _subtotal = (venta['total'] as num).toDouble();
        if (clienteEncontrado != null) {
          _clienteSeleccionado = clienteEncontrado;
        }

        for (var p in productos) {
          _carrito.add({
            'nombre_producto': p['nombre_producto'] ?? p['nombre'] ?? 'Producto',
            'precio_unitario': (p['precio_unitario'] ?? (p['total'] as num) / (p['cant'] ?? 1)) as num,
          });
        }
      });
    } catch (e) {
      debugPrint("Error al clonar: $e");
    }
  }

  double get _totalFinal {
    double total = _subtotal;
    if (_aplicarImpuesto) {
      total += (_subtotal * (_ivaConfigurado / 100));
    }
    return total;
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
      _subtotal += (producto['precio_unitario'] as num).toDouble();
    });
  }

  void _quitarDelCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) return;

    final index = _carrito.indexWhere((item) => item['nombre_producto'] == producto['nombre_producto']);
    if (index != -1) {
      setState(() {
        _carrito.removeAt(index);
        _subtotal -= (producto['precio_unitario'] as num).toDouble();
        if (_subtotal < 0) _subtotal = 0.0;
      });
    }
  }

  Future<void> _finalizarVenta() async {
    if (_clienteSeleccionado == null || _carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("⚠️ Carrito vacío o cliente no seleccionado")));
      return;
    }

    Map<String, dynamic> datosVenta = {
      'total': _totalFinal,
      'productos_detalle': jsonEncode(_carrito),
      'metodo_pago': 'Efectivo',
    };

    await PdfGenerator.generarFactura(datosVenta, _aplicarImpuesto, _ivaConfigurado);

    await DatabaseHelper.instance.insertarVenta({
      'cliente_id': _clienteSeleccionado!['id'],
      'total': _totalFinal,
      'fecha': DateTime.now().toString(),
      'productos_detalle': jsonEncode(_carrito),
      'metodo_pago': 'Efectivo',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Venta registrada y generada")));

    setState(() {
      _carrito.clear();
      _subtotal = 0.0;
      _clienteSeleccionado = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Facturación")),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Cliente", border: OutlineInputBorder()),
                value: _clienteSeleccionado?['id'],
                items: _clientes.map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(c['nombre_empresa'] as String),
                )).toList(),
                onChanged: (int? id) {
                  if (id != null) {
                    setState(() {
                      _clienteSeleccionado = _clientes.firstWhere((c) => c['id'] == id);
                    });
                  }
                },
              ),
            ),
            SwitchListTile(
              title: Text("Aplicar IVA (${_ivaConfigurado.toInt()}%)"),
              value: _aplicarImpuesto,
              onChanged: (val) => setState(() => _aplicarImpuesto = val),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _prods.length,
                itemBuilder: (c, i) {
                  final producto = _prods[i];
                  final cantidadSeleccionada = _contarEnCarrito(producto['nombre_producto']);

                  return ListTile(
                    title: Text(producto['nombre_producto'] as String),
                    subtitle: Text("\$${producto['precio_unitario']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mostrar botón de restar y contador solo si hay al menos 1 seleccionado
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
                        // Botón de sumar
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => _agregarAlCarrito(producto),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: \$${_totalFinal.toInt()}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ElevatedButton.icon(
                    onPressed: _finalizarVenta,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Generar"),
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