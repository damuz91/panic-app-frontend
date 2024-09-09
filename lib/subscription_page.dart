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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
      });
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    const Set<String> _kIds = {'your_subscription_id_here'};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error
    }
    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> _buySubscription(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suscripción'),
      ),
      body: Center(
        child: _isAvailable
            ? ListView.builder(
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
        )
            : Text('Store is not available'),
      ),
    );
  }
}
