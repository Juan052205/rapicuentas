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
    });
  }

  Future<void> _guardar() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.actualizarDatosPago(
        _nequi.text.trim(),
        _davi.text.trim(),
        _ahorro.text.trim(),
      );
      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text("Cuentas y Métodos de Pago")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Texto de contexto
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

              // Nequi
              TextField(
                controller: _nequi,
                keyboardType: TextInputType.phone,
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

              // Daviplata
              TextField(
                controller: _davi,
                keyboardType: TextInputType.phone,
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

              // Cuenta de ahorros
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

              const SizedBox(height: 32),

              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}