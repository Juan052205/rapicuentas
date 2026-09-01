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
  final TextEditingController _ivaController = TextEditingController();

  String _logoPath = '';
  bool _isLoading = false;
  int _esPro = 0;
  bool _datosCargados = false;

  String _nombreInicial = '';
  String _nitInicial = '';
  String _dirInicial = '';
  String _resolucionInicial = '';
  String _prefijoInicial = 'FE';
  String _ivaInicial = '19';
  String _logoPathInicial = '';

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
    _ivaController.dispose();
    super.dispose();
  }

  String _sinPlaceholder(String? valor, List<String> placeholders) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return '';
    for (final p in placeholders) {
      if (v.toLowerCase() == p.toLowerCase()) return '';
    }
    return v;
  }

  Future<void> _cargarAjustes() async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    final nombre = _sinPlaceholder(ajustes['nombre_negocio']?.toString(), ['Mi Negocio', 'RECIBO']);
    final nit = _sinPlaceholder(ajustes['nit']?.toString(), ['N/A', 'No definido']);
    final dir = _sinPlaceholder(ajustes['direccion']?.toString(), ['Sin dirección', 'No definido']);
    final resolucion = (ajustes['resolucion_dian'] ?? '').toString();
    final prefijo = (ajustes['prefijo_factura'] ?? 'FE').toString();
    final iva = (ajustes['iva_porcentaje'] as num?)?.toDouble() ?? 19.0;
    final ivaTexto = iva == iva.roundToDouble() ? iva.toInt().toString() : iva.toString();
    final logo = ajustes['logo_path'] ?? '';

    if (!mounted) return;
    setState(() {
      _nombreController.text = nombre;
      _nitController.text = nit;
      _dirController.text = dir;
      _resolucionDianController.text = resolucion;
      _prefijoController.text = prefijo.isEmpty ? 'FE' : prefijo;
      _ivaController.text = ivaTexto;
      _logoPath = logo;
      _esPro = ajustes['es_pro'] ?? 0;

      _nombreInicial = nombre;
      _nitInicial = nit;
      _dirInicial = dir;
      _resolucionInicial = resolucion;
      _prefijoInicial = _prefijoController.text;
      _ivaInicial = ivaTexto;
      _logoPathInicial = logo;
      _datosCargados = true;
    });
  }

  bool _hayCambios() {
    if (!_datosCargados) return false;
    return _nombreController.text.trim() != _nombreInicial ||
        _nitController.text.trim() != _nitInicial ||
        _dirController.text.trim() != _dirInicial ||
        _resolucionDianController.text.trim() != _resolucionInicial ||
        _prefijoController.text.trim().toUpperCase() != _prefijoInicial.toUpperCase() ||
        _ivaController.text.trim() != _ivaInicial ||
        _logoPath != _logoPathInicial;
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
        content: const Text("Si sales ahora se perderán los datos que acabas de escribir. ¿Qué deseas hacer?"),
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
      await _guardarCambios();
    }
  }

  Future<void> _seleccionarYRecortarLogo() async {
    if (_esPro == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El logotipo corporativo es exclusivo de la versión Pro")),
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
        const SnackBar(content: Text("Logotipo ajustado y seleccionado con éxito")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al procesar imagen: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _eliminarLogo() {
    setState(() {
      _logoPath = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logotipo removido. Recuerda guardar cambios.")),
    );
  }

  Future<void> _guardarCambios() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    try {
      String prefijoFinal = _prefijoController.text.trim().toUpperCase();
      if (prefijoFinal.isEmpty) prefijoFinal = 'FE';

      double ivaFinal = double.tryParse(_ivaController.text.trim().replaceAll(',', '.')) ?? 19.0;
      if (ivaFinal < 0) ivaFinal = 0;
      if (ivaFinal > 100) ivaFinal = 100;

      await DatabaseHelper.instance.actualizarConfiguracion(
        _nombreController.text.trim(),
        _nitController.text.trim(),
        _dirController.text.trim(),
        ivaFinal,
        prefijo: prefijoFinal,
      );
      await DatabaseHelper.instance.actualizarResolucionDian(_resolucionDianController.text.trim());
      await DatabaseHelper.instance.actualizarLogoPath(_logoPath);

      if (!mounted) return;

      _nombreInicial = _nombreController.text.trim();
      _nitInicial = _nitController.text.trim();
      _dirInicial = _dirController.text.trim();
      _resolucionInicial = _resolucionDianController.text.trim();
      _prefijoInicial = prefijoFinal;
      _ivaInicial = _ivaController.text.trim();
      _logoPathInicial = _logoPath;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Configuración guardada con éxito"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _deco({
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade50,
      helperText: helper,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _intentarSalir();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Ajustes del Negocio"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _intentarSalir,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nombreController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _deco(
                          label: "Nombre del negocio",
                          hint: "Ej: Abarrotes Don Pedro",
                          icon: Icons.store,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nitController,
                        textInputAction: TextInputAction.next,
                        decoration: _deco(
                          label: "NIT",
                          hint: "Ej: 900123456-1",
                          icon: Icons.badge,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _dirController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _deco(
                          label: "Dirección",
                          hint: "Ej: Calle 10 #5-20, Centro",
                          icon: Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ivaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: _deco(
                          label: "IVA por defecto (%)",
                          hint: "Ej: 19",
                          icon: Icons.percent,
                          helper: "Se usa al activar IVA en una factura.",
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: _prefijoController,
                              decoration: _deco(
                                label: "Prefijo",
                                hint: "Ej: FAC",
                                icon: Icons.numbers,
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 6,
                            child: TextField(
                              controller: _resolucionDianController,
                              decoration: _deco(
                                label: "Resolución DIAN",
                                hint: "Ej: 18764000000000",
                                icon: Icons.verified_outlined,
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
                          Expanded(
                            child: Text(
                              "Personalización Pro (Logotipo)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
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
                            "Activa la versión Pro para recortar y habilitar tu logotipo en los recibos.",
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
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
                  child: ElevatedButton(
                    onPressed: _guardarCambios,
                    child: const Text("GUARDAR CAMBIOS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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