import 'package:flutter/material.dart';
import 'database_helper.dart';

class ClientesPantalla extends StatefulWidget {
  const ClientesPantalla({super.key});

  @override
  State<ClientesPantalla> createState() => _ClientesPantallaState();
}

class _ClientesPantallaState extends State<ClientesPantalla> {
  final _nombreController = TextEditingController();
  final _idController = TextEditingController();
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    final data = await DatabaseHelper.instance.obtenerClientes();
    setState(() => _clientes = data);
  }

  Future<void> _guardarCliente() async {
    if (_nombreController.text.isNotEmpty) {
      await DatabaseHelper.instance.insertarCliente({
        'nombre_empresa': _nombreController.text,
        'identificacion': _idController.text,
      });
      _nombreController.clear();
      _idController.clear();
      _cargarClientes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cliente registrado")));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Gestión de Clientes")),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre / Empresa")),
              TextField(controller: _idController, decoration: const InputDecoration(labelText: "Identificación (NIT/CC)")),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _guardarCliente, child: const Text("Registrar Cliente")),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _clientes.length,
            itemBuilder: (c, i) => ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text(_clientes[i]['nombre_empresa']),
              subtitle: Text(_clientes[i]['identificacion']),
            ),
          ),
        ),
      ],
    ),
  );
}