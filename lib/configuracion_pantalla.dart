import 'package:flutter/material.dart';
import 'database_helper.dart';

class ConfiguracionPantalla extends StatefulWidget {
  const ConfiguracionPantalla({super.key});
  @override
  State<ConfiguracionPantalla> createState() => _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends State<ConfiguracionPantalla> {
  final _nequi = TextEditingController();
  final _davi = TextEditingController();
  final _ahorro = TextEditingController();

  @override
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final datos = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _nequi.text = datos['nequi'] ?? '';
      _davi.text = datos['daviplata'] ?? '';
      _ahorro.text = datos['cuenta_ahorros'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Configurar Pagos")),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      TextField(controller: _nequi, decoration: const InputDecoration(labelText: "Nequi")),
      TextField(controller: _davi, decoration: const InputDecoration(labelText: "Daviplata")),
      TextField(controller: _ahorro, decoration: const InputDecoration(labelText: "Cta Ahorros")),
      ElevatedButton(
        onPressed: () async {
          await DatabaseHelper.instance.actualizarDatosPago(_nequi.text, _davi.text, _ahorro.text);

          if (!mounted) return;

          // Con esta línea, le decimos al analizador: "Ya validé la seguridad, confía en mí"
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Guardado exitosamente"))
          );
        },
        child: const Text("Guardar"),
      )
    ])),
  );
}