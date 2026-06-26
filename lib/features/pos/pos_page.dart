import 'package:flutter/material.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/product_service.dart';
import '../../data/services/settings_service.dart';

class PosPage extends StatefulWidget {
  final ProductService productService;
  final SettingsService settingsService;

  const PosPage({
    super.key,
    required this.productService,
    required this.settingsService,
  });

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  late final ProductService _productService;
  late final SettingsService _settingsService;

  late String _selectedPaymentMethod;

  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _barcodeFocusNode = FocusNode();

  final List<CartItemModel> _cart = [];

  String _searchQuery = '';
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();

    _productService = widget.productService;
    _settingsService = widget.settingsService;

    _selectedPaymentMethod = _settingsService.settings.defaultPaymentMethod;

    _settingsService.addListener(_onSettingsChanged);
    _productService.setCurrentCartCount(0);
  }

  void _onSettingsChanged() {
    setState(() {
      _selectedPaymentMethod = _settingsService.settings.defaultPaymentMethod;
    });
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);

    _barcodeController.dispose();
    _searchController.dispose();
    _barcodeFocusNode.dispose();

    super.dispose();
  }

  int _quantityInCart(ProductModel product) {
    final index = _cart.indexWhere((item) => item.product.name == product.name);
    if (index == -1) return 0;
    return _cart[index].quantity;
  }

  bool _canAddProduct(ProductModel product) {
    if (!_settingsService.settings.preventNegativeStock) return true;
    return _quantityInCart(product) < product.stock;
  }

  void _syncCartCount() {
    final totalItems = _cart.fold(0, (sum, item) => sum + item.quantity);
    _productService.setCurrentCartCount(totalItems);
  }

  void _addToCart(ProductModel product) {
    final settings = _settingsService.settings;

    final cartIndex = _cart.indexWhere(
      (item) => item.product.name == product.name,
    );

    final currentQuantityInCart = cartIndex == -1
        ? 0
        : _cart[cartIndex].quantity;

    final requestedQuantity = currentQuantityInCart + 1;

    if (settings.preventNegativeStock && requestedQuantity > product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock insuffisant pour ${product.name}. Stock disponible : ${product.stock}',
          ),
          backgroundColor: Colors.red,
        ),
      );

      _barcodeFocusNode.requestFocus();
      return;
    }

    setState(() {
      if (cartIndex != -1) {
        _cart[cartIndex].quantity++;
      } else {
        _cart.add(
          CartItemModel(
            product: product,
          ),
        );
      }
    });

    _syncCartCount();
    _barcodeFocusNode.requestFocus();
  }

  void _onBarcodeSubmitted(String value) {
    final barcode = value.trim();

    if (barcode.isEmpty) return;

    final product = _productService.findByBarcode(barcode);

    _barcodeController.clear();

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun produit trouvé pour le code : $barcode'),
          backgroundColor: Colors.red,
        ),
      );

      _barcodeFocusNode.requestFocus();
      return;
    }

    _addToCart(product);
  }

  void _updateQuantity(int index, int delta) {
    final item = _cart[index];
    final latestProduct = item.product.id == null
        ? item.product
        : _productService.products.firstWhere(
            (p) => p.id == item.product.id,
            orElse: () => item.product,
          );

    if (_settingsService.settings.preventNegativeStock &&
        delta > 0 &&
        item.quantity >= latestProduct.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock maximum atteint pour ${item.product.name}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _cart[index].quantity += delta;

      if (_cart[index].quantity <= 0) {
        _cart.removeAt(index);
      }
    });

    _syncCartCount();
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });

    _syncCartCount();
    _barcodeFocusNode.requestFocus();
  }

  double get _total {
    return _cart.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty || _isCheckingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer l\'encaissement'),
          content: Text(
            'Total : ${_total.toStringAsFixed(2)} €\n'
            'Paiement : $_selectedPaymentMethod\n\n'
            'Confirmer la vente ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      _barcodeFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });

    try {
      final saleTotal = _total;

      for (final item in _cart) {
        if (item.product.id != null) {
          await _productService.decrementStock(
            item.product.id!,
            item.quantity,
          );
        }
      }

      _productService.addSale(saleTotal);

      if (!mounted) return;

      setState(() {
        _cart.clear();
      });

      _syncCartCount();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      _barcodeFocusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _productService,
      builder: (context, _) {
        final products = _searchQuery.trim().isEmpty
            ? _productService.products
            : _productService.search(_searchQuery);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Scannez un code-barres',
                          prefixIcon: Icon(Icons.qr_code_scanner),
                        ),
                        onSubmitted: _onBarcodeSubmitted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Rechercher un produit',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: products.isEmpty
                        ? const Center(
                            child: Text('Aucun produit dans le catalogue'),
                          )
                        : GridView.builder(
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.6,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final canAdd = _canAddProduct(product);

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: canAdd ? () => _addToCart(product) : null,
                                  child: Opacity(
                                    opacity: canAdd ? 1 : 0.5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${product.price.toStringAsFixed(2)} €',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Stock : ${product.stock}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 360,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Panier',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (_cart.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearCart,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Vider'),
                            ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _cart.isEmpty
                            ? const Center(
                                child: Text('Aucun article dans le panier'),
                              )
                            : ListView.builder(
                                itemCount: _cart.length,
                                itemBuilder: (context, index) {
                                  final item = _cart[index];

                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge,
                                              ),
                                              Text(
                                                '${item.product.price.toStringAsFixed(2)} € × ${item.quantity}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _updateQuantity(index, -1),
                                              icon: const Icon(Icons.remove,
                                                  size: 18),
                                            ),
                                            Text(
                                              item.quantity.toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge,
                                            ),
                                            IconButton(
                                              onPressed: !_settingsService
                                                          .settings
                                                          .preventNegativeStock ||
                                                      item.quantity <
                                                          item.product.stock
                                                  ? () =>
                                                      _updateQuantity(index, 1)
                                                  : null,
                                              icon: const Icon(Icons.add,
                                                  size: 18),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            '${item.subtotal.toStringAsFixed(2)} €',
                                            textAlign: TextAlign.right,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${_total.toStringAsFixed(2)} €',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cart.isEmpty || _isCheckingOut
                              ? null
                              : _checkout,
                          icon: _isCheckingOut
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payment),
                          label: Text(
                            _isCheckingOut ? 'Encaissement...' : 'Encaisser',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
