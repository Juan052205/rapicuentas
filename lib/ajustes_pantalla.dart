import 'package:flutter/material.dart';
import 'database_helper.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final TextEditingController _nombreController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    setState(() => _isLoading = true);
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    _nombreController.text = ajustes['nombre_negocio'] ?? 'Mi Negocio';
    setState(() => _isLoading = false);
  }

  Future<void> _guardarCambios() async {
    if (_nombreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ El nombre no puede estar vacío")),
      );
      return;
    }

    await DatabaseHelper.instance.actualizarNombreNegocio(_nombreController.text);

    if (!mounted) return;

    // Feedback visual profesional
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Branding actualizado correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    // Volvemos atrás tras guardar
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración de Negocio"),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Personalización de Branding",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del Negocio en PDF",
                prefixIcon: Icon(Icons.store),
                border: OutlineInputBorder(),
                hintText: "Ej: Almojábanas El Tío",
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _guardarCambios,
              icon: const Icon(Icons.save),
              label: const Text("GUARDAR CONFIGURACIÓN"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.blueGrey.shade900,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}