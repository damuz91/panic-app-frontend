import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;
  List<PurchaseDetails> _purchases = [];

  @override
  void initState() {
    super.initState();
    _initialize();
    // Listen for purchase updates
    _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
      _processPurchaseUpdates(purchaseDetailsList);
    });
  }

  Future<void> _initialize() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
      });
      await _loadProducts();
      // No need to load past purchases since we will track them via the stream
    } else {
      setState(() {
        _isAvailable = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    const Set<String> _kIds = {'base'}; // IDs de tus productos de suscripción
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);

    if (response.error != null) {
      setState(() {
        _queryProductError = response.error?.message;
      });
    }

    if (response.notFoundIDs.isNotEmpty) {
      // Manejo de IDs no encontrados
      print('No se encontraron algunos productos: ${response.notFoundIDs}');
    }

    setState(() {
      _products = response.productDetails;
    });
  }

  void _processPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Handle successful purchase
        _verifyPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _purchasePending = true;
        });
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle purchase error
        setState(() {
          _purchasePending = false;
          _queryProductError = purchaseDetails.error?.message;
        });
      }
    }

    // Update the state with the latest purchases
    setState(() {
      _purchases = purchaseDetailsList; // Store the latest purchase details
    });
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Implement your own verification logic here
    // For example, you can send the purchase details to your server for validation
    // After verification, you may want to complete the purchase
    _inAppPurchase.completePurchase(purchaseDetails);

    setState(() {
      _purchasePending = false;
    });
  }

  Future<void> _buySubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    setState(() {
      _purchasePending = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final purchasedProductIds = _purchases.map((purchase) => purchase.productID).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Suscripciones'),
      ),
      body: Center(
        child: _isAvailable
            ? _products.isNotEmpty
            ? Column(
          children: [
            // Mostrar suscripción actual
            if (purchasedProductIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Suscripción activa: ${purchasedProductIds.join(', ')}',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
            // Mostrar lista de suscripciones disponibles
            Expanded(
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.description),
                    trailing: ElevatedButton(
                      onPressed: () => _buySubscription(product),
                      child: Text(product.price),
                    ),
                  );
                },
              ),
            ),
          ],
        )
            : _purchasePending
            ? CircularProgressIndicator() // Muestra un indicador de carga mientras se procesa la compra
            : Text('No hay productos disponibles en este momento')
            : Text(_queryProductError ?? 'La tienda no está disponible'),
      ),
    );
  }
}
