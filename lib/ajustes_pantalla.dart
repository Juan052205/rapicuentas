import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database_helper.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _dirController = TextEditingController();
  final TextEditingController _resolucionDianController = TextEditingController();
  final TextEditingController _prefijoController = TextEditingController();

  String _logoPath = '';
  bool _isLoading = false;
  int _esPro = 0;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nitController.dispose();
    _dirController.dispose();
    _resolucionDianController.dispose();
    _prefijoController.dispose();
    super.dispose();
  }

  Future<void> _cargarAjustes() async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    setState(() {
      _nombreController.text = ajustes['nombre_negocio'] ?? '';
      _nitController.text = ajustes['nit'] ?? '';
      _dirController.text = ajustes['direccion'] ?? '';
      _resolucionDianController.text = ajustes['resolucion_dian'] ?? '';
      _prefijoController.text = ajustes['prefijo_factura'] ?? 'FE';
      _logoPath = ajustes['logo_path'] ?? '';
      _esPro = ajustes['es_pro'] ?? 0;
    });
  }

  Future<void> _seleccionarYRecortarLogo() async {
    if (_esPro == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🔒 El logotipo corporativo es exclusivo de la versión Pro")),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imagenSeleccionada = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (imagenSeleccionada == null) return;

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagenSeleccionada.path,
        compressFormat: ImageCompressFormat.png,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Logotipo',
            toolbarColor: Colors.blue.shade800,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.blue.shade900,
            activeControlsWidgetColor: Colors.blue.shade800,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            hideBottomControls: false,
            showCropGrid: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          IOSUiSettings(
            title: 'Ajustar Logotipo',
          ),
        ],
      );

      if (croppedFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = p.basename(croppedFile.path);
      final savedImage = await File(croppedFile.path).copy('${directory.path}/$fileName');

      setState(() {
        _logoPath = savedImage.path;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Logotipo ajustado y seleccionado con éxito")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al procesar imagen: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _eliminarLogo() {
    setState(() {
      _logoPath = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Logotipo removido. Recuerda guardar cambios.")),
    );
  }

  Future<void> _guardarCambios() async {
    setState(() => _isLoading = true);

    try {
      String prefijoFinal = _prefijoController.text.trim().toUpperCase();
      if (prefijoFinal.isEmpty) prefijoFinal = 'FE';

      await DatabaseHelper.instance.actualizarConfiguracion(
        _nombreController.text,
        _nitController.text,
        _dirController.text,
        19.0,
        prefijo: prefijoFinal,
      );
      await DatabaseHelper.instance.actualizarResolucionDian(_resolucionDianController.text);
      await DatabaseHelper.instance.actualizarLogoPath(_logoPath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Configuración guardada con éxito"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajustes del Negocio")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre Negocio", border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
              const SizedBox(height: 15),
              TextField(controller: _nitController, decoration: const InputDecoration(labelText: "NIT", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 15),
              TextField(controller: _dirController, decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: _prefijoController,
                      decoration: const InputDecoration(
                        labelText: "Prefijo (Ej: FAC)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: TextField(
                      controller: _resolucionDianController,
                      decoration: const InputDecoration(
                        labelText: "Resolución DIAN",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.amber),
                  SizedBox(width: 8),
                  Text("Personalización Pro (Logotipo)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _logoPath.isNotEmpty && File(_logoPath).existsSync()
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(File(_logoPath), fit: BoxFit.cover),
                      )
                          : const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Logotipo de Factura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            _logoPath.isNotEmpty ? "Imagen activa" : "Sin logotipo",
                            style: TextStyle(fontSize: 11, color: _logoPath.isNotEmpty ? Colors.green.shade700 : Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _esPro == 1 ? _seleccionarYRecortarLogo : null,
                          icon: Icon(_esPro == 1 ? Icons.crop : Icons.lock, size: 14),
                          label: Text(_esPro == 1 ? "Editar" : "Pro"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _esPro == 1 ? Colors.blue : Colors.grey.shade300,
                            foregroundColor: _esPro == 1 ? Colors.white : Colors.grey.shade700,
                            minimumSize: const Size(80, 32),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        if (_logoPath.isNotEmpty && _esPro == 1)
                          TextButton.icon(
                            onPressed: _eliminarLogo,
                            icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                            label: const Text("Quitar", style: TextStyle(fontSize: 11, color: Colors.red)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(80, 24)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_esPro == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "🔒 Activa la versión Pro para recortar y habilitar tu logotipo en los recibos.",
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardarCambios,
                  child: const Text("GUARDAR CAMBIOS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}