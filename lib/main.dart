import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'clientes_pantalla.dart';
import 'productos_pantalla.dart';
import 'GeneradorCuentasPantalla.dart';
import 'historial_ventas_pantalla.dart';
import 'ajustes_hub_pantalla.dart';
import 'play_billing_service.dart';
import 'play_integrity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const SplashScreen(),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    await PlayIntegrityService.verificarLicenciaYPlayStore();
    await DatabaseHelper.instance.obtenerDatosPago();
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NavegacionPrincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.35),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.white, size: 58),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Rapicuentas",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Facturación y Gestión Profesional",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 2;
  bool _mostrarBienvenidaOverlay = false;

  @override
  void initState() {
    super.initState();
    _verificarPrimerInicioUnicaVez();

    // Callback que se ejecuta cuando se compra o se restaura Pro
    PlayBillingService().inicializar(() {
      if (!mounted) return;

      // Mostramos el mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 ¡Versión Pro activada con éxito a través de Google Play!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Reinicio rápido de la app (cierra y abre la pantalla principal)
      // Esto fuerza a que todas las pantallas se creen de nuevo y lean el nuevo estado Pro
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const NavegacionPrincipal(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
              (route) => false,
        );
      });
    });
  }

  Future<void> _verificarPrimerInicioUnicaVez() async {
    bool mostrar = await DatabaseHelper.instance.debeMostrarBienvenida();
    if (mostrar) {
      await DatabaseHelper.instance.marcarBienvenidaVista();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        setState(() => _mostrarBienvenidaOverlay = true);
      });
    }
  }

  void _cerrarBienvenida() {
    setState(() => _mostrarBienvenidaOverlay = false);
  }

  void _mostrarGuiaAyuda() {
    setState(() => _mostrarBienvenidaOverlay = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _indiceActual,
            children: [
              const ClientesPantalla(),
              const ProductosPantalla(),
              const GeneradorCuentasPantalla(),
              HistorialVentasPantalla(visible: _indiceActual == 3),
              const AjustesHubPantalla(),
            ],
          ),
          if (_mostrarBienvenidaOverlay)
            AnimatedOpacity(
              opacity: _mostrarBienvenidaOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Guía Rápida Rapicuentas",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                              onPressed: _cerrarBienvenida,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Optimiza tu negocio y factura con nivel gerencial usando estas secciones clave:",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        _buildItemGuia(
                          icon: Icons.people_outline,
                          titulo: "1. Clientes",
                          descripcion: "Registra la base de tus compradores o empresas frecuentes.",
                        ),
                        _buildItemGuia(
                          icon: Icons.inventory_2_outlined,
                          titulo: "2. Productos",
                          descripcion: "Administra tu catálogo de productos y precios unitarios.",
                        ),
                        _buildItemGuia(
                          icon: Icons.receipt_long_outlined,
                          titulo: "3. Facturar",
                          descripcion: "Selecciona cliente, productos y genera tu recibo PDF de inmediato.",
                          destacado: true,
                        ),
                        _buildItemGuia(
                          icon: Icons.history,
                          titulo: "4. Historial",
                          descripcion: "Administra, comparte o clona ventas pasadas.\n• Tip Pro: Toca 📊 para ver métricas avanzadas.",
                          destacado: true,
                        ),
                        _buildItemGuia(
                          icon: Icons.settings_outlined,
                          titulo: "5. Ajustes",
                          descripcion: "Configura datos de tu negocio, métodos de pago (Nequi/Daviplata) y diseño de recibos.",
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _cerrarBienvenida,
                            child: const Text("¡Entendido, a facturar!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        tooltip: "Guía e Instrucciones",
        onPressed: _mostrarGuiaAyuda,
        child: const Icon(Icons.help_outline),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (int index) {
          setState(() {
            _indiceActual = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Productos'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Facturar'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }

  Widget _buildItemGuia({required IconData icon, required String titulo, required String descripcion, bool destacado = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: destacado ? Colors.blue.shade50.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: destacado ? Colors.blue.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(descripcion, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}