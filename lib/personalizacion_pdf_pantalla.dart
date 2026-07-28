import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'database_helper.dart';
import 'play_integrity_service.dart';

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

  final List<Map<String, dynamic>> _coloresDisponibles = [
    {'nombre': 'Azul Ejecutivo', 'color': Colors.blue.shade800, 'pdfColor': PdfColors.blue800},
    {'nombre': 'Azul Rey', 'color': Colors.indigo, 'pdfColor': PdfColors.indigo},
    {'nombre': 'Verde Esmeralda', 'color': Colors.green.shade800, 'pdfColor': PdfColors.green800},
    {'nombre': 'Verde Oliva', 'color': Colors.teal, 'pdfColor': PdfColors.teal},
    {'nombre': 'Rojo Elegante', 'color': Colors.red.shade800, 'pdfColor': PdfColors.red800},
    {'nombre': 'Vino Tinto', 'color': Colors.purple, 'pdfColor': PdfColors.purple},
    {'nombre': 'Naranja Corporativo', 'color': Colors.orange.shade800, 'pdfColor': PdfColors.orange800},
    {'nombre': 'Gris Carbón', 'color': Colors.grey.shade800, 'pdfColor': PdfColors.grey800},
    {'nombre': 'Marrón Café', 'color': Colors.brown, 'pdfColor': PdfColors.brown},
    {'nombre': 'Azul Océano', 'color': Colors.cyan.shade800, 'pdfColor': PdfColors.cyan800},
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
      _isLoading = false;
    });
  }

  Future<void> _guardarEstilos() async {
    if (_esPro == 0) {
      _mostrarModalPro();
      return;
    }

    await DatabaseHelper.instance.actualizarEstilosPdf(_colorSeleccionado, _estiloTablaSeleccionado);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ ¡Diseño de recibos actualizado con éxito!"), backgroundColor: Colors.green),
    );
  }

  void _mostrarModalPro() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Función Exclusiva Pro",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "Personaliza los colores corporativos y estilos de tus recibos PDF para darle una imagen impecable a tu negocio.\n\n"
              "Hazte Pro para habilitar esta y todas las herramientas gerenciales.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(c);
              bool esLegitimo = await PlayIntegrityService.verificarLicenciaYPlayStore();

              if (!context.mounted) return;
              if (!esLegitimo) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Verificación de Play Integrity fallida."), backgroundColor: Colors.red),
                );
                return;
              }

              await DatabaseHelper.instance.actualizarEstadoPro(1);
              setState(() => _esPro = 1);

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🚀 ¡Versión Pro activada con éxito!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Hacerme Pro"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Diseño y Estilo Pro")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

            const Text("🎨 Selecciona el Color Corporativo (10 Opciones)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text("Este color se aplicará en los títulos, totales y líneas principales de tus recibos PDF.", style: TextStyle(fontSize: 12, color: Colors.grey)),
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

            const Text("📊 Estilo de la Tabla de Productos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Formato del Recibo"),
              value: _estiloTablaSeleccionado,
              items: const [
                DropdownMenuItem(
                  value: 0,
                  child: Text("Estándar Corporativo (Fondo Sombreado)", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: 1,
                  child: Text("Minimalista Ejecutivo (Líneas Limpias)", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                ),
              ],
              selectedItemBuilder: (BuildContext context) {
                return [
                  const Text("Estándar Corporativo (Fondo Sombreado)", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                  const Text("Minimalista Ejecutivo (Líneas Limpias)", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                ];
              },
              onChanged: (val) => setState(() => _estiloTablaSeleccionado = val!),
            ),

            const SizedBox(height: 30),
            SizedBox(
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
                  _esPro == 1 ? "GUARDAR DISEÑO PRO" : "ACTIVAR CON VERSIÓN PRO",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}