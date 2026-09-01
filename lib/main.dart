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
import 'widgets/guia_rapida_dialog.dart';

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
  final GlobalKey<ClientesPantallaState> _clientesKey = GlobalKey<ClientesPantallaState>();
  final GlobalKey<ProductosPantallaState> _productosKey = GlobalKey<ProductosPantallaState>();
  final GlobalKey<GeneradorCuentasPantallaState> _facturarKey = GlobalKey<GeneradorCuentasPantallaState>();

  @override
  void initState() {
    super.initState();
    _verificarPrimerInicioUnicaVez();

    PlayBillingService().inicializar(() {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚀 ¡Versión Pro activada con éxito a través de Google Play!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        mostrarGuiaRapidaRapicuentas(context);
      });
    }
  }

  void _mostrarGuiaAyuda() {
    mostrarGuiaRapidaRapicuentas(context);
  }

  Future<void> _cambiarPestana(int index) async {
    if (index == _indiceActual) return;

    String? mensajePendiente;
    if (_indiceActual == 0 && (_clientesKey.currentState?.tieneDatosSinGuardar ?? false)) {
      mensajePendiente = "Tienes un cliente escrito que aún no has registrado. Regístralo con el botón azul para no perderlo.";
    } else if (_indiceActual == 1 && (_productosKey.currentState?.tieneDatosSinGuardar ?? false)) {
      mensajePendiente = "Tienes un producto escrito que aún no has guardado. Púlsalo en Guardar Producto para no perderlo.";
    }

    if (mensajePendiente != null) {
      final irse = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Cambios sin guardar"),
          content: Text(mensajePendiente!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Seguir aquí"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Salir de todos modos"),
            ),
          ],
        ),
      );
      if (irse != true) return;
    }

    if (!mounted) return;
    setState(() {
      _indiceActual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _indiceActual,
        children: [
          ClientesPantalla(key: _clientesKey),
          ProductosPantalla(key: _productosKey),
          GeneradorCuentasPantalla(
            key: _facturarKey,
            visible: _indiceActual == 2,
            onAyuda: _mostrarGuiaAyuda,
          ),
          HistorialVentasPantalla(visible: _indiceActual == 3),
          const AjustesHubPantalla(),
        ],
      ),
      floatingActionButton: _indiceActual == 2
          ? null
          : FloatingActionButton(
        mini: true,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        tooltip: "Guía e Instrucciones",
        onPressed: _mostrarGuiaAyuda,
        child: const Icon(Icons.help_outline),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: _cambiarPestana,
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
}