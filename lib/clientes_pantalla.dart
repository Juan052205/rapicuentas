import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/cliente.dart';
import 'widgets/pro_upsell_modal.dart';

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
  final _busquedaController = TextEditingController();
  List<Cliente> _clientes = [];
  int? _esPro = DatabaseHelper.instance.esProEnMemoria;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _idController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    final data = await DatabaseHelper.instance.obtenerClientesModelo();
    final datosPago = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _clientes = data;
      _esPro = datosPago['es_pro'] ?? 0;
    });
  }

  List<Cliente> get _clientesFiltrados {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _clientes;
    return _clientes.where((c) {
      return c.nombreEmpresa.toLowerCase().contains(q) ||
          c.identificacion.toLowerCase().contains(q) ||
          c.telefono.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _guardarCliente() async {
    if (_nombreController.text.isNotEmpty) {
      final nuevoCliente = Cliente(
        nombreEmpresa: _nombreController.text,
        identificacion: _idController.text.isNotEmpty ? _idController.text : 'Consumidor Final',
        telefono: _telefonoController.text,
        direccion: _direccionController.text,
      );

      await DatabaseHelper.instance.insertarClienteModelo(nuevoCliente);
      _nombreController.clear();
      _idController.clear();
      _telefonoController.clear();
      _direccionController.clear();
      _cargarClientes();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cliente registrado con éxito"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el nombre del cliente o empresa"), backgroundColor: Colors.orange),
      );
    }
  }

  void _mostrarFormularioEdicion(Cliente cliente) {
    final editNombre = TextEditingController(text: cliente.nombreEmpresa);
    final editId = TextEditingController(text: cliente.identificacion);
    final editTelefono = TextEditingController(text: cliente.telefono);
    final editDireccion = TextEditingController(text: cliente.direccion);

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
          TextButton(
            onPressed: () {
              editNombre.dispose();
              editId.dispose();
              editTelefono.dispose();
              editDireccion.dispose();
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editNombre.text.isNotEmpty) {
                final clienteActualizado = Cliente(
                  id: cliente.id,
                  nombreEmpresa: editNombre.text,
                  identificacion: editId.text.isNotEmpty ? editId.text : 'Consumidor Final',
                  telefono: editTelefono.text,
                  direccion: editDireccion.text,
                );

                await DatabaseHelper.instance.actualizarClienteModelo(clienteActualizado);

                editNombre.dispose();
                editId.dispose();
                editTelefono.dispose();
                editDireccion.dispose();

                if (!context.mounted) return;
                Navigator.pop(context);
                _cargarClientes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cliente actualizado con éxito"), backgroundColor: Colors.green),
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
              if (!context.mounted) return;
              Navigator.pop(context);
              _cargarClientes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cliente eliminado"), backgroundColor: Colors.red),
              );
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonPro() {
    if (_esPro != 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Center(
        child: InkWell(
          onTap: () => ProUpsellModal.mostrar(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.orange.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.35),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 15),
                SizedBox(width: 4),
                Text(
                  "PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _clientesFiltrados;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Gestión de Clientes"),
        actions: [_buildBotonPro()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "Clientes Registrados (${filtrados.length}${_busqueda.isEmpty ? '' : ' de ${_clientes.length}'})",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _busquedaController,
                      decoration: InputDecoration(
                        hintText: "Buscar por nombre, NIT o teléfono...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _busqueda.isEmpty
                            ? null
                            : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _busquedaController.clear();
                            setState(() => _busqueda = '');
                          },
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _busqueda = v),
                    ),
                  ],
                ),
              ),
              filtrados.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      _clientes.isEmpty ? "No hay clientes registrados aún" : "Sin resultados para la búsqueda",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtrados.length,
                itemBuilder: (c, i) {
                  final cliente = filtrados[i];
                  String nombre = cliente.nombreEmpresa;
                  String nit = cliente.identificacion;
                  String tel = cliente.telefono;
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
                            onPressed: () => cliente.id != null ? _confirmarEliminar(cliente.id!) : null,
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
      ),
    );
  }
}