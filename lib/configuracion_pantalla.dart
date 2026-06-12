import 'package:flutter/material.dart';
import 'database_helper.dart';

class ConfiguracionPantalla extends StatelessWidget {
  const ConfiguracionPantalla({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración de Pago")),
      body: const Center(child: Text("Aquí irían tus TextFields para configurar Nequi/Daviplata")),
    );
  }
}