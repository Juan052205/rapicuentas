import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/ajustes.dart';
import 'ajustes_pantalla.dart';
import 'configuracion_pantalla.dart';
import 'personalizacion_pdf_pantalla.dart';
import 'widgets/comparacion_pro_widget.dart';
import 'widgets/pro_upsell_modal.dart';
import 'play_billing_service.dart';

class AjustesHubPantalla extends StatefulWidget {
  const AjustesHubPantalla({super.key});

  @override
  State<AjustesHubPantalla> createState() => _AjustesHubPantallaState();
}

class _AjustesHubPantallaState extends State<AjustesHubPantalla> {
  Ajustes? _ajustes;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarAjustes();
  }

  Future<void> _cargarAjustes() async {
    final data = await DatabaseHelper.instance.obtenerAjustes();
    if (!mounted) return;
    setState(() {
      _ajustes = data;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Centro de Ajustes"),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _cargarAjustes,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTarjetaProStatus(),
              const SizedBox(height: 16),
              _buildOpcionHub(
                icon: Icons.storefront_outlined,
                colorIcono: Colors.blue.shade800,
                titulo: "Datos del Negocio y Logo",
                subtitulo: "Nombre, NIT, Dirección, Resolución DIAN y Logotipo corporativo",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjustesScreen()),
                  );
                  _cargarAjustes();
                },
              ),
              const SizedBox(height: 12),
              _buildOpcionHub(
                icon: Icons.account_balance_wallet_outlined,
                colorIcono: Colors.green.shade700,
                titulo: "Cuentas y Métodos de Pago",
                subtitulo: "Configura tus cuentas de Nequi, Daviplata y Ahorros",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfiguracionPantalla()),
                  );
                  _cargarAjustes();
                },
              ),
              const SizedBox(height: 12),
              _buildOpcionHub(
                icon: Icons.palette_outlined,
                colorIcono: Colors.purple,
                titulo: "Diseño y Estilo del Recibo PDF",
                subtitulo: "Colores corporativos, formato de tablas y vista previa Pro",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonalizacionPdfPantalla()),
                  );
                  _cargarAjustes();
                },
              ),
              const SizedBox(height: 16),
              const ComparacionProWidget(),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await PlayBillingService().restaurarCompras();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🔄 Solicitud de restauración enviada a Google Play Store"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _cargarAjustes();
                  },
                  icon: const Icon(Icons.restore, color: Colors.grey, size: 18),
                  label: const Text(
                    "Restablecer compras previas",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaProStatus() {
    bool esPro = _ajustes?.esPro == 1;
    return InkWell(
      onTap: () {
        if (!esPro) {
          ProUpsellModal.mostrar(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: esPro
                ? [Colors.blue.shade900, Colors.blue.shade700]
                : [Colors.amber.shade800, Colors.amber.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (esPro ? Colors.blue : Colors.amber).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              esPro ? Icons.workspace_premium : Icons.stars_outlined,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esPro ? "Licencia Rapicuentas Pro Activa" : "Versión Gratuita / Freemium",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    esPro
                        ? "Acceso ilimitado sin anuncios y personalización completa."
                        : "Te restan ${_ajustes?.intentosClonacionRestantes ?? 3} clonaciones. Toca para ser Pro 🚀",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!esPro)
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionHub({
    required IconData icon,
    required Color colorIcono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorIcono.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorIcono, size: 24),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}