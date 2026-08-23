import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'database_helper.dart';

class PlayBillingService {
  static final PlayBillingService _instance = PlayBillingService._internal();
  factory PlayBillingService() => _instance;
  PlayBillingService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const String _kProProductId = 'rapicuentas_pro_version';

  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  Future<void> inicializar(Function onProActivado) async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint("⚠️ La tienda de Google Play no esta disponible.");
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _procesarActualizacionesCompra(purchaseDetailsList, onProActivado);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint("❌ Error en el stream de compras: $error");
    });

    await cargarProductos();
  }

  Future<void> cargarProductos() async {
    const Set<String> ids = <String>{_kProProductId};
    ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint("⚠️ Producto no encontrado en Google Play Console: ${response.notFoundIDs}");
    }

    _products = response.productDetails;
  }

  Future<void> comprarVersionPro() async {
    if (_products.isEmpty) {
      debugPrint("⚠️ No hay productos cargados para la compra.");
      await cargarProductos();
      if (_products.isEmpty) return;
    }

    ProductDetails? productDetails;
    try {
      productDetails = _products.firstWhere(
            (element) => element.id == _kProProductId,
      );
    } catch (e) {
      productDetails = null;
    }

    if (productDetails == null && _products.isNotEmpty) {
      productDetails = _products.first;
    }

    if (productDetails == null) {
      debugPrint("⚠️ No se encontró ningún producto disponible para comprar.");
      return;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _procesarActualizacionesCompra(
      List<PurchaseDetails> purchaseDetailsList, Function onProActivado) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("⏳ Compra pendiente...");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("❌ Error en la compra: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          await DatabaseHelper.instance.actualizarEstadoPro(1);
          onProActivado();
          debugPrint("🚀 ¡Versión Pro activada mediante Google Play Billing!");
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}