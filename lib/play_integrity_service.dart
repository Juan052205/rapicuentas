import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlayIntegrityService {
  static const MethodChannel _channel = MethodChannel('com.tuempresa.rapicuentas/integrity');

  /// Verifica si la instalación proviene legítimamente de Google Play Store
  static Future<bool> verificarLicenciaYPlayStore() async {
    // Si estamos en modo de desarrollo o debug, permitimos pruebas locales
    if (kDebugMode) {
      debugPrint("🛡️ [Play Integrity] Modo Debug detectado: Omitiendo verificación estricta de Play Store.");
      return true;
    }

    try {
      final bool esLegitimo = await _channel.invokeMethod('verificarIntegridadPlay');
      return esLegitimo;
    } catch (e) {
      debugPrint("❌ Error al verificar Play Integrity: $e");
      return false;
    }
  }
}