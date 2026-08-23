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
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
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
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
      });
      _nombreController.clear();
      _idController.clear();
      _telefonoController.clear();
      _direccionController.clear();
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

  void _mostrarFormularioEdicion(Map<String, dynamic> cliente) {
    final editNombre = TextEditingController(text: cliente['nombre_empresa']);
    final editId = TextEditingController(text: cliente['identificacion']);
    final editTelefono = TextEditingController(text: cliente['telefono'] ?? '');
    final editDireccion = TextEditingController(text: cliente['direccion'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: editNombre, decoration: const InputDecoration(labelText: "Nombre / Empresa")),
              const SizedBox(height: 10),
              TextField(controller: editId, decoration: const InputDecoration(labelText: "Identificación (NIT / CC)")),
              const SizedBox(height: 10),
              TextField(controller: editTelefono, decoration: const InputDecoration(labelText: "Teléfono (Opcional)")),
              const SizedBox(height: 10),
              TextField(controller: editDireccion, decoration: const InputDecoration(labelText: "Dirección (Opcional)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (editNombre.text.isNotEmpty) {
                await DatabaseHelper.instance.actualizarCliente(cliente['id'], {
                  'nombre_empresa': editNombre.text,
                  'identificacion': editId.text.isNotEmpty ? editId.text : 'Consumidor Final',
                  'telefono': editTelefono.text,
                  'direccion': editDireccion.text,
                });
                Navigator.pop(context);
                _cargarClientes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Cliente actualizado con éxito"), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Cliente"),
        content: const Text("¿Estás seguro de que deseas eliminar este cliente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await DatabaseHelper.instance.eliminarCliente(id);
              Navigator.pop(context);
              _cargarClientes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🗑️ Cliente eliminado"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Gestión de Clientes")),
    // 🛠️ Toda la pantalla ahora es un SingleChildScrollView unificado
    body: SingleChildScrollView(
      child: Column(
        children: [
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: "Teléfono (Opcional)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: "Dirección (Opcional)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on_outlined),
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
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
          Container(
            width: double.infinity,
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
          _clientes.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(40.0),
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
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _clientes.length,
            itemBuilder: (c, i) {
              final cliente = _clientes[i];
              String nombre = cliente['nombre_empresa'] ?? 'Cliente';
              String nit = cliente['identificacion'] ?? 'N/A';
              String tel = cliente['telefono'] ?? '';
              String inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                    child: Text(inicial, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("NIT/CC: $nit ${tel.isNotEmpty ? '| Tel: $tel' : ''}", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                        onPressed: () => _mostrarFormularioEdicion(cliente),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _confirmarEliminar(cliente['id']),
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
  );
}