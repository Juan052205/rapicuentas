import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'database_helper.dart';
import 'play_billing_service.dart';

class PersonalizacionPdfPantalla extends StatefulWidget {
  const PersonalizacionPdfPantalla({super.key});

  @override
  State<PersonalizacionPdfPantalla> createState() => _PersonalizacionPdfPantallaState();
}

class _PersonalizacionPdfPantallaState extends State<PersonalizacionPdfPantalla> {
  int _esPro = 0;
  int _colorSeleccionado = 0;
  int _estiloTablaSeleccionado = 0;
  bool _isLoading = true;
  int _colorInicial = 0;
  int _estiloInicial = 0;

  final List<Map<String, dynamic>> _coloresDisponibles = [
    {'nombre': 'Azul Ejecutivo', 'color': Colors.blue.shade800, 'pdfColor': PdfColors.blue800},
    {'nombre': 'Azul Rey', 'color': Colors.indigo, 'pdfColor': PdfColors.indigo},
    {'nombre': 'Verde Esmeralda', 'color': Colors.green.shade800, 'pdfColor': PdfColors.green800},
    {'nombre': 'Verde Oliva', 'color': Colors.teal, 'pdfColor': PdfColors.teal},
    {'nombre': 'Rojo Elegante', 'color': Colors.red.shade800, 'pdfColor': PdfColors.red800},
    {'nombre': 'Vino Tinto', 'color': Colors.purple, 'pdfColor': PdfColors.purple},
    {'nombre': 'Naranja Corporativo', 'color': Colors.orange.shade800, 'pdfColor': PdfColors.orange800},
    {'nombre': 'Gris Carbon', 'color': Colors.grey.shade800, 'pdfColor': PdfColors.grey800},
    {'nombre': 'Marron Cafe', 'color': Colors.brown, 'pdfColor': PdfColors.brown},
    {'nombre': 'Azul Oceano', 'color': Colors.cyan.shade800, 'pdfColor': PdfColors.cyan800},
  ];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final datos = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _esPro = datos['es_pro'] ?? 0;
      _colorSeleccionado = datos['pdf_color_index'] ?? 0;
      _estiloTablaSeleccionado = datos['pdf_estilo_tabla'] ?? 0;
      _colorInicial = _colorSeleccionado;
      _estiloInicial = _estiloTablaSeleccionado;
      _isLoading = false;
    });
  }

  bool _hayCambios() {
    return _colorSeleccionado != _colorInicial || _estiloTablaSeleccionado != _estiloInicial;
  }

  Future<void> _intentarSalir() async {
    if (!_hayCambios()) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final accion = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Cambios sin guardar"),
        content: const Text("El color o el diseño del recibo no se han guardado. ¿Qué deseas hacer?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'seguir'),
            child: const Text("Seguir aquí"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'salir'),
            child: const Text("Salir sin guardar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, 'guardar'),
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (accion == 'salir') {
      Navigator.pop(context);
    } else if (accion == 'guardar') {
      await _guardarEstilos();
    }
  }

  Future<void> _guardarEstilos() async {
    if (_esPro == 0) {
      _mostrarModalPro();
      return;
    }

    await DatabaseHelper.instance.actualizarEstilosPdf(_colorSeleccionado, _estiloTablaSeleccionado);
    _colorInicial = _colorSeleccionado;
    _estiloInicial = _estiloTablaSeleccionado;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ ¡Diseño de recibos actualizado con éxito!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  void _mostrarModalPro() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Función Exclusiva Pro",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "Personaliza los colores corporativos y el diseño de tus recibos PDF para darle una imagen impecable a tu negocio.\n\n"
              "Hazte Pro para habilitar esta y todas las herramientas gerenciales.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(c);
              await PlayBillingService().comprarVersionPro();
            },
            child: const Text("Hacerme Pro"),
          ),
        ],
      ),
    );
  }

  Widget _miniRecibo({required int estilo, required Color color}) {
    return Container(
      height: 86,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (estilo == 1)
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            )
          else if (estilo == 2) ...[
            Row(
              children: [
                Expanded(child: Container(height: 6, color: Colors.grey.shade400)),
                const SizedBox(width: 16),
                Container(height: 8, width: 28, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 2, width: 70, color: color),
          ] else
            Row(
              children: [
                Expanded(child: Container(height: 8, color: Colors.grey.shade400)),
                const SizedBox(width: 8),
                Container(
                  height: 18,
                  width: 32,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Container(height: 6, width: 90, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          if (estilo == 0) ...[
            Container(height: 8, width: double.infinity, color: color.withOpacity(0.85)),
            Container(height: 8, width: double.infinity, color: Colors.grey.shade200),
            Container(height: 8, width: double.infinity, color: Colors.white),
          ] else if (estilo == 1) ...[
            Container(height: 8, width: double.infinity, color: color.withOpacity(0.85)),
            Container(height: 1, width: double.infinity, color: Colors.grey.shade300),
            const SizedBox(height: 4),
            Container(height: 1, width: double.infinity, color: Colors.grey.shade300),
          ] else ...[
            Container(height: 1, width: double.infinity, color: Colors.grey.shade400),
            const SizedBox(height: 5),
            Container(height: 1, width: double.infinity, color: Colors.grey.shade300),
            const SizedBox(height: 5),
            Container(height: 1, width: double.infinity, color: Colors.grey.shade300),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaEstilo({
    required int valor,
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    final seleccionado = _estiloTablaSeleccionado == valor;
    return InkWell(
      onTap: () => setState(() => _estiloTablaSeleccionado = valor),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? color : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  seleccionado ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: seleccionado ? color : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: seleccionado ? color : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(descripcion, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3)),
            const SizedBox(height: 10),
            _miniRecibo(estilo: valor, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorActivo = _coloresDisponibles[_colorSeleccionado.clamp(0, _coloresDisponibles.length - 1)]['color'] as Color;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _intentarSalir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Diseño y Estilo Pro"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _intentarSalir,
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_esPro == 0)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: Colors.amber, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Modo de Vista Previa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text("Prueba los diseños y activa Pro para guardarlos en tus recibos.", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Text("Color de tu negocio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text("Este color se usa en el encabezado, títulos y el total de tus recibos PDF.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 15),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _coloresDisponibles.length,
                        itemBuilder: (context, index) {
                          final item = _coloresDisponibles[index];
                          bool seleccionado = _colorSeleccionado == index;

                          return InkWell(
                            onTap: () => setState(() => _colorSeleccionado = index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: seleccionado ? item['color'].withOpacity(0.15) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: seleccionado ? item['color'] : Colors.grey.shade300,
                                  width: seleccionado ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: item['color'],
                                      shape: BoxShape.circle,
                                    ),
                                    child: seleccionado ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['nombre'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                                        color: seleccionado ? item['color'] : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      const Divider(),
                      const SizedBox(height: 15),
                      const Text("Diseño del recibo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text("Elige cómo se ve la factura. Toca una tarjeta para previsualizar el estilo.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _tarjetaEstilo(
                        valor: 0,
                        titulo: "Clásico",
                        descripcion: "Recuadro de color con el número de factura y filas intercaladas. Ideal para un look tradicional.",
                        color: colorActivo,
                      ),
                      const SizedBox(height: 10),
                      _tarjetaEstilo(
                        valor: 1,
                        titulo: "Moderno",
                        descripcion: "Franja de color a lo ancho en la parte superior. Se ve actual y muy profesional.",
                        color: colorActivo,
                      ),
                      const SizedBox(height: 10),
                      _tarjetaEstilo(
                        valor: 2,
                        titulo: "Elegante",
                        descripcion: "Diseño limpio, con más espacio en blanco y una línea de acento. Perfecto para negocios premium.",
                        color: colorActivo,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _esPro == 1 ? Colors.blue : Colors.amber.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _guardarEstilos,
                    icon: Icon(_esPro == 1 ? Icons.save : Icons.workspace_premium),
                    label: Text(
                      _esPro == 1 ? "GUARDAR DISEÑO PRO" : "ACTIVAR CON VERSION PRO",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}