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
        'identificacion': _idController.text.isNotEmpty ? _idController.text : 'Consumidor Final',
      });
      _nombreController.clear();
      _idController.clear();
      _cargarClientes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cliente registrado con éxito"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ingresa el nombre del cliente o empresa"), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Gestión de Clientes")),
    body: Column(
      children: [
        // Tarjeta de Formulario con Estilo Ejecutivo
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.5),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Registrar Nuevo Cliente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
              const SizedBox(height: 10),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre / Empresa",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "Identificación (NIT / CC)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _guardarCliente,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text("Registrar Cliente", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),

        // Cabecera de Lista
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text("Clientes Registrados (${_clientes.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),

        // Lista Estilizada de Clientes
        Expanded(
          child: _clientes.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text("No hay clientes registrados aún", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _clientes.length,
            itemBuilder: (c, i) {
              final cliente = _clientes[i];
              String nombre = cliente['nombre_empresa'] ?? 'Cliente';
              String nit = cliente['identificacion'] ?? 'N/A';
              String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                    child: Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("NIT/CC: $nit", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}