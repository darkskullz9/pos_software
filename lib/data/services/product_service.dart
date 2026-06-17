import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import 'barcode_service.dart';
import 'database_service.dart';

class ProductService extends ChangeNotifier {
  ProductService() {
    loadProducts();
  }

  final _barcodeService = BarcodeService();
  final _databaseService = DatabaseService.instance;

  final List<ProductModel> _products = [];

  double _salesTotal = 0;
  int _currentCartCount = 0;
  bool _isLoading = false;

  List<ProductModel> get products => List.unmodifiable(_products);
  double get salesTotal => _salesTotal;
  int get currentCartCount => _currentCartCount;
  bool get isLoading => _isLoading;

  int get totalStock => _products.fold(0, (sum, product) => sum + product.stock);

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _databaseService.getProducts();
      _products
        ..clear()
        ..addAll(items);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(ProductModel product) async {
    final barcode = product.barcode ??
        _barcodeService.generateClothingBarcode(
          productIndex: _products.length,
          categoryCode: product.categoryCode,
          colorCode: product.colorCode,
          sizeCode: product.sizeCode,
        );

    final productToInsert = product.copyWith(barcode: barcode);

    final id = await _databaseService.insertProduct(productToInsert);

    final savedProduct = productToInsert.copyWith(id: id);

    _products.insert(0, savedProduct);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) {
      throw Exception('Impossible de mettre à jour un produit sans id');
    }

    await _databaseService.updateProduct(product);

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  Future<void> updateProductBarcode(int productId, String barcode) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final updated = _products[index].copyWith(barcode: barcode);
    await _databaseService.updateProduct(updated);

    _products[index] = updated;
    notifyListeners();
  }

  Future<void> deleteProduct(int productId) async {
    await _databaseService.deleteProduct(productId);
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> incrementStock(int productId, int quantity) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final product = _products[index];
    final updated = product.copyWith(
      stock: product.stock + quantity,
    );

    await _databaseService.updateProduct(updated);
    _products[index] = updated;
    notifyListeners();
  }

  Future<void> decrementStock(int productId, int quantity) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final product = _products[index];
    final updated = product.copyWith(
      stock: (product.stock - quantity).clamp(0, product.stock).toInt(),
    );

    await _databaseService.updateProduct(updated);
    _products[index] = updated;
    notifyListeners();
  }

  void setCurrentCartCount(int count) {
    _currentCartCount = count;
    notifyListeners();
  }

  void addSale(double total) {
    _salesTotal += total;
    notifyListeners();
  }

  ProductModel? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> search(String query) {
    if (query.trim().isEmpty) {
      return List.unmodifiable(_products);
    }

    final normalizedQuery = query.toLowerCase().trim();

    return _products.where((product) {
      return product.name.toLowerCase().contains(normalizedQuery) ||
          (product.brand?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
  }
}