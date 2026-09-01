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
  bool _isLoading = false;
  bool _datosCargados = false;

  String _nequiInicial = '';
  String _daviInicial = '';
  String _ahorroInicial = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nequi.dispose();
    _davi.dispose();
    _ahorro.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final datos = await DatabaseHelper.instance.obtenerDatosPago();
    if (!mounted) return;
    setState(() {
      _nequi.text = datos['nequi'] ?? '';
      _davi.text = datos['daviplata'] ?? '';
      _ahorro.text = datos['cuenta_ahorros'] ?? '';
      _nequiInicial = _nequi.text;
      _daviInicial = _davi.text;
      _ahorroInicial = _ahorro.text;
      _datosCargados = true;
    });
  }

  bool _hayCambios() {
    if (!_datosCargados) return false;
    return _nequi.text.trim() != _nequiInicial ||
        _davi.text.trim() != _daviInicial ||
        _ahorro.text.trim() != _ahorroInicial;
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
        content: const Text("Si sales ahora se perderán los números de cuenta que escribiste. ¿Qué deseas hacer?"),
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
      await _guardar();
    }
  }

  Future<void> _guardar() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.actualizarDatosPago(
        _nequi.text.trim(),
        _davi.text.trim(),
        _ahorro.text.trim(),
      );
      if (!mounted) return;
      _nequiInicial = _nequi.text.trim();
      _daviInicial = _davi.text.trim();
      _ahorroInicial = _ahorro.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cuentas de pago guardadas"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          title: const Text("Cuentas y Métodos de Pago"),
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
                  padding: const EdgeInsets.all(20.0),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade800, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Estos números aparecen en el PDF cuando el cliente paga por Nequi, Daviplata o transferencia. Déjalos vacíos si no los usas.",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.blue.shade900,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Medios de cobro",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nequi,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Nequi",
                          hintText: "Ej: 3001234567",
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_android, color: Colors.purple.shade700),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _davi,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: "Daviplata",
                          hintText: "Ej: 3009876543",
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Colors.red.shade700),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _ahorro,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Cuenta de ahorros / Bancaria",
                          hintText: "Número de cuenta",
                          border: const OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance, color: Colors.green.shade700),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Opcional: banco y tipo de cuenta puedes escribirlos en Observaciones de cada factura.",
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
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
                  child: ElevatedButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      "GUARDAR CUENTAS",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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