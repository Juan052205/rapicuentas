import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'ajustes_hub_pantalla.dart';
import 'widgets/guia_facturar_tip.dart';

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

  bool _mostrarTutorial = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cargarDatosYClonacion();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosYClonacion() async {
    final p = await DatabaseHelper.instance.obtenerProductosActivos();
    final c = await DatabaseHelper.instance.obtenerClientes();
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    bool debeMostrarTip = await DatabaseHelper.instance.debeMostrarTutorialFacturar();

    if (!mounted) return;
    setState(() {
      _prods = p.map((e) => Map<String, dynamic>.from(e)).toList();
      _clientes = c;
      _ivaPorcentaje = (ajustes['iva_porcentaje'] as num?)?.toDouble() ?? 19.0;
      _mostrarTutorial = debeMostrarTip;

      if (_clienteSeleccionado != null) {
        try {
          _clienteSeleccionado = _clientes.firstWhere((cli) => cli['id'] == _clienteSeleccionado!['id']);
        } catch (_) {
          _clienteSeleccionado = null;
        }
      }

      if (widget.ventaAClonar != null && _carrito.isEmpty) {
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

  void _ocultarTutorialManual() {
    setState(() {
      _mostrarTutorial = false;
    });
    DatabaseHelper.instance.marcarTutorialFacturarVisto();
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

      final ajustes = await DatabaseHelper.instance.obtenerAjustes();

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

      if (ajustes.esPro == 0 && ajustes.logoPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Venta registrada. 💡 Agrega tu logotipo corporativo en Ajustes."),
            backgroundColor: Colors.blue.shade900,
            duration: const Duration(seconds: 5),
            showCloseIcon: true,
            closeIconColor: Colors.amber,
            action: SnackBarAction(
              label: "CONFIGURAR",
              textColor: Colors.amber,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AjustesHubPantalla()),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Venta registrada y generada con éxito")));
      }
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
  Widget build(BuildContext context) {
    double valorIva = _aplicarIva ? (_total * (_ivaPorcentaje / 100)) : 0.0;
    double valorRetencion = (_retencionPorcentaje > 0) ? (_total * (_retencionPorcentaje / 100)) : 0.0;
    double totalFinalCalculado = _total + valorIva - valorRetencion;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nueva Cuenta"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recargar Datos",
            onPressed: _cargarDatosYClonacion,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Centro de Ajustes",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AjustesHubPantalla()),
              );
              _cargarDatosYClonacion();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SECCIÓN SUPERIOR FIJA: Cliente y Tipo de Pago
              Container(
                padding: const EdgeInsets.all(12.0),
                color: Colors.white,
                child: Column(
                  children: [
                    if (_mostrarTutorial && _carrito.isEmpty) ...[
                      if (_clienteSeleccionado == null)
                        GuiaFacturarTip(
                          texto: "Paso 1: Elige el cliente de la factura",
                          onCerrar: _ocultarTutorialManual,
                        )
                      else
                        GuiaFacturarTip(
                          texto: "Paso 2: Toca + para agregar productos",
                          onCerrar: _ocultarTutorialManual,
                        ),
                    ],
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Cliente",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      value: _clienteSeleccionado?['id'],
                      hint: const Text("Seleccionar Cliente"),
                      items: _clientes.isEmpty
                          ? [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("⚠️ Sin clientes. Registra uno en Clientes"),
                        )
                      ]
                          : _clientes
                          .map((c) => DropdownMenuItem<int>(
                        value: c['id'] as int,
                        child: Text(c['nombre_empresa'] ?? '', overflow: TextOverflow.ellipsis),
                      ))
                          .toList(),
                      onChanged: _clientes.isEmpty
                          ? null
                          : (int? nuevoId) => setState(() =>
                      _clienteSeleccionado = _clientes.firstWhere((c) => c['id'] == nuevoId)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Tipo Doc.",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            value: _tipoDocumentoSeleccionado,
                            items: _tiposDocumento
                                .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            ))
                                .toList(),
                            onChanged: (val) => setState(() => _tipoDocumentoSeleccionado = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Pago",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            value: _metodoSeleccionado,
                            items: _metodos
                                .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            ))
                                .toList(),
                            onChanged: (val) => setState(() => _metodoSeleccionado = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SECCIÓN COLAPSIBLE DE OPCIONES SECUNDARIAS
              ExpansionTile(
                dense: true,
                title: Text(
                  "Opciones y Resumen (${_carrito.length} ítems)",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                leading: const Icon(Icons.tune, size: 18, color: Colors.blue),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          dense: true,
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
                        const SizedBox(height: 8),
                        TextField(
                          controller: _observacionesController,
                          decoration: const InputDecoration(
                            labelText: "Observaciones / Términos (Opcional)",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 1,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "👤 Client: ${_clienteSeleccionado?['nombre_empresa'] ?? 'Sin seleccionar'}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "📦 Carrito: ${_carrito.length} ítems",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _carrito.isNotEmpty ? Colors.green.shade800 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              ),

              // ENCABEZADO DE PRODUCTOS
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      "Productos (${_prods.length})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
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

              // LISTA DE PRODUCTOS CON DESPLAZAMIENTO SEGURO
              _prods.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      "No hay productos en el inventario",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Agrega productos en la pestaña 'Productos' para seleccionarlos aquí.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _cargarDatosYClonacion,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Recargar Lista"),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
            ],
          ),
        ),
      ),

      // BARRA INFERIOR FIJA DE TOTALES CON PROTECCIÓN CONTRA DESBORDAMIENTO HORIZONTAL
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(top: BorderSide(color: Colors.blue.shade200, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            "Subtotal: \$${_total.toStringAsFixed(0)}",
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                          ),
                          if (_aplicarIva) ...[
                            const SizedBox(width: 6),
                            Text(
                              "IVA: +\$${valorIva.toStringAsFixed(0)}",
                              style: TextStyle(fontSize: 10.5, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (_retencionPorcentaje > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              "Ret: -\$${valorRetencion.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 10.5, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "TOTAL: \$${totalFinalCalculado.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _finalizarVenta,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text("Finalizar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}