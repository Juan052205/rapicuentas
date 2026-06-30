import 'package:flutter/material.dart';
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

  // ¡FALTABA ESTA VARIABLE! Sin ella, el código no compila
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final ajustes = await DatabaseHelper.instance.obtenerDatosPago();
    _nombreController.text = ajustes['nombre_negocio'] ?? '';
    _nitController.text = ajustes['nit'] ?? '';
    _dirController.text = ajustes['direccion'] ?? '';
  }

  Future<void> _guardarCambios() async {
    setState(() => _isLoading = true);

    try {
      await DatabaseHelper.instance.actualizarConfiguracion(
          _nombreController.text, _nitController.text, _dirController.text, 19.0
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Configuración guardada"),
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
        child: Column(
          children: [
            TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre Negocio", border: OutlineInputBorder(), prefixIcon: Icon(Icons.store))),
            const SizedBox(height: 15),
            TextField(controller: _nitController, decoration: const InputDecoration(labelText: "NIT", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
            const SizedBox(height: 15),
            TextField(controller: _dirController, decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
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
    );
  }
}