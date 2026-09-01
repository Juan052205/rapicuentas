import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'pdf_generator.dart';
import 'ajustes_hub_pantalla.dart';
import 'formato_cop.dart';
import 'vista_previa_pdf_pantalla.dart';
import 'widgets/guia_facturar_tip.dart';
import 'widgets/guia_rapida_dialog.dart';
import 'widgets/pro_upsell_modal.dart';

class GeneradorCuentasPantalla extends StatefulWidget {
  final Map<String, dynamic>? ventaAClonar;
  final bool visible;
  final VoidCallback? onAyuda;

  const GeneradorCuentasPantalla({
    super.key,
    this.ventaAClonar,
    this.visible = true,
    this.onAyuda,
  });

  @override
  State<GeneradorCuentasPantalla> createState() => GeneradorCuentasPantallaState();
}

class GeneradorCuentasPantallaState extends State<GeneradorCuentasPantalla> {
  List<Map<String, dynamic>> _prods = [];
  List<Map<String, dynamic>> _clientes = [];
  final List<Map<String, dynamic>> _carrito = [];
  Map<String, dynamic>? _clienteSeleccionado;
  double _total = 0.0;

  bool _mostrarTutorial = false;
  int? _esPro = DatabaseHelper.instance.esProEnMemoria;

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
  final TextEditingController _filtroProductoController = TextEditingController();
  String _filtroProducto = '';

  bool get tieneDatosSinGuardar =>
      _carrito.isNotEmpty || _clienteSeleccionado != null || _observacionesController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargarDatosYClonacion();
  }

  @override
  void didUpdateWidget(GeneradorCuentasPantalla oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _cargarDatosYClonacion();
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _filtroProductoController.dispose();
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
      _esPro = ajustes['es_pro'] ?? 0;
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
        _aplicarIva = (venta['aplicar_iva'] as num?)?.toInt() == 1;
        if (venta['iva_porcentaje'] != null) {
          final ivaClon = (venta['iva_porcentaje'] as num).toDouble();
          if (ivaClon > 0) _ivaPorcentaje = ivaClon;
        }
        _retencionSeleccionada = (venta['retencion_tipo'] ?? 'Ninguna').toString();
        if (!_opcionesRetenciones.containsKey(_retencionSeleccionada)) {
          _retencionSeleccionada = 'Ninguna';
        }
        _retencionPorcentaje = (venta['retencion_porcentaje'] as num?)?.toDouble()
            ?? (_opcionesRetenciones[_retencionSeleccionada] ?? 0.0);

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
                  content: Text("Precio actualizado para esta factura"),
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

  void _recalcularTotal() {
    _total = 0.0;
    for (final item in _carrito) {
      _total += (item['precio_unitario'] as num).toDouble();
    }
    if (_total < 0) _total = 0.0;
  }

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona un cliente primero")));
      return;
    }
    setState(() {
      _carrito.add({
        'nombre_producto': producto['nombre_producto'],
        'precio_unitario': (producto['precio_unitario'] as num),
      });
      _recalcularTotal();
    });
  }

  void _quitarDelCarrito(Map<String, dynamic> producto) {
    if (_clienteSeleccionado == null) return;

    final index = _carrito.indexWhere((item) => item['nombre_producto'] == producto['nombre_producto']);
    if (index != -1) {
      setState(() {
        _carrito.removeAt(index);
        _recalcularTotal();
      });
    }
  }

  void _establecerCantidad(Map<String, dynamic> producto, int cantidad) {
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecciona un cliente primero")));
      return;
    }
    final nombre = producto['nombre_producto'];
    final precio = (producto['precio_unitario'] as num);
    final n = cantidad < 0 ? 0 : cantidad;

    setState(() {
      _carrito.removeWhere((item) => item['nombre_producto'] == nombre);
      for (int i = 0; i < n; i++) {
        _carrito.add({
          'nombre_producto': nombre,
          'precio_unitario': precio,
        });
      }
      _recalcularTotal();
    });
  }

  void _editarCantidad(Map<String, dynamic> producto) {
    final actual = _contarEnCarrito(producto['nombre_producto']);
    final controller = TextEditingController(text: actual.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cantidad: ${producto['nombre_producto']}"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Cantidad",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final n = int.tryParse(controller.text.trim()) ?? actual;
            Navigator.pop(ctx);
            _establecerCantidad(producto, n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim()) ?? actual;
              Navigator.pop(ctx);
              _establecerCantidad(producto, n);
            },
            child: const Text("Aplicar"),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirVistaPrevia(Map<String, dynamic> venta, String numeroFactura, {String? extra}) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaPreviaPdfPantalla(
          venta: venta,
          mensajeCabecera: extra ??
              "Venta $numeroFactura registrada. Usa compartir para enviarla o la impresora para guardar/imprimir.",
        ),
      ),
    );
  }

  Future<void> _finalizarVenta() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_clienteSeleccionado == null || _carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Carrito vacío o cliente no seleccionado")));
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
      final numeroFactura = await DatabaseHelper.instance.asignarNumeroFactura();

      final nuevaVenta = {
        'cliente_id': _clienteSeleccionado!['id'],
        'total': _total,
        'fecha': DateTime.now().toString(),
        'productos_detalle': jsonProductos,
        'metodo_pago': _metodoSeleccionado,
        'tipo_documento': _tipoDocumentoSeleccionado,
        'observaciones': _observacionesController.text,
        'aplicar_iva': _aplicarIva ? 1 : 0,
        'iva_porcentaje': _aplicarIva ? _ivaPorcentaje : 0.0,
        'retencion_tipo': _retencionSeleccionada,
        'retencion_porcentaje': _retencionPorcentaje,
        'numero_factura': numeroFactura,
      };

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

      String extra = "Venta $numeroFactura registrada. Comparte o imprime desde aquí, sin volver al historial.";
      if (ajustes.esPro == 0 && ajustes.logoPath.isEmpty) {
        extra = "Venta $numeroFactura registrada. Comparte o imprime aquí. En Ajustes puedes agregar tu logotipo (Pro).";
      }

      try {
        await PdfGenerator.conAnuncioSiAplica(() async {
          await _abrirVistaPrevia(nuevaVenta, numeroFactura, extra: extra);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Venta $numeroFactura guardada. El PDF no se pudo generar: ${e.toString().replaceAll("Exception: ", "")}",
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
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

  Widget _buildBotonPro() {
    if (_esPro != 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
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

  List<Map<String, dynamic>> get _prodsVisibles {
    final q = _filtroProducto.trim().toLowerCase();
    if (q.isEmpty) return _prods;
    return _prods.where((p) {
      return (p['nombre_producto'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double valorIva = _aplicarIva ? (_total * (_ivaPorcentaje / 100)) : 0.0;
    double valorRetencion = (_retencionPorcentaje > 0) ? (_total * (_retencionPorcentaje / 100)) : 0.0;
    double totalFinalCalculado = _total + valorIva - valorRetencion;
    final visibles = _prodsVisibles;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Nueva Cuenta"),
        actions: [
          _buildBotonPro(),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "Guía rápida",
            onPressed: widget.onAyuda ?? () => mostrarGuiaRapidaRapicuentas(context),
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
                          child: Text("Sin clientes. Registra uno en Clientes"),
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
                                  "Cliente: ${_clienteSeleccionado?['nombre_empresa'] ?? 'Sin seleccionar'}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "Carrito: ${_carrito.length} ítems",
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

              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "Productos (${visibles.length})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                        ),
                        const Spacer(),
                        Text(
                          "Toca el número para cantidad",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _filtroProductoController,
                      decoration: InputDecoration(
                        hintText: "Buscar producto...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _filtroProducto.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _filtroProductoController.clear();
                            setState(() => _filtroProducto = '');
                          },
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _filtroProducto = v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Colors.grey),

              visibles.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      _prods.isEmpty ? "No hay productos en el inventario" : "Sin resultados para la búsqueda",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _prods.isEmpty
                          ? "Agrega productos en la pestaña 'Productos' para seleccionarlos aquí."
                          : "Prueba con otro nombre.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                itemCount: visibles.length,
                itemBuilder: (c, i) {
                  final producto = visibles[i];
                  final cantidadSeleccionada = _contarEnCarrito(producto['nombre_producto']);
                  final indexOriginal = _prods.indexOf(producto);

                  return Card(
                    child: ListTile(
                      title: Text(producto['nombre_producto']),
                      subtitle: InkWell(
                        onTap: () => _editarPrecioTemporalProducto(indexOriginal >= 0 ? indexOriginal : i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                FormatoCop.pesos(producto['precio_unitario'] as num),
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
                            InkWell(
                              onTap: () => _editarCantidad(producto),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                child: Text(
                                  '$cantidadSeleccionada',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
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
                            "Subtotal: ${FormatoCop.pesos(_total)}",
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                          ),
                          if (_aplicarIva) ...[
                            const SizedBox(width: 6),
                            Text(
                              "IVA: +${FormatoCop.pesos(valorIva)}",
                              style: TextStyle(fontSize: 10.5, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (_retencionPorcentaje > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              "Ret: -${FormatoCop.pesos(valorRetencion)}",
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
                        "TOTAL: ${FormatoCop.pesos(totalFinalCalculado)}",
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