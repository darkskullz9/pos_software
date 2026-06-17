import 'package:flutter/foundation.dart';

import '../models/product_model.dart';
import 'barcode_service.dart';

class ProductService extends ChangeNotifier {
  final _barcodeService = BarcodeService();

  final List<ProductModel> _products = [];

  double _salesTotal = 0;
  int _currentCartCount = 0;

  List<ProductModel> get products => List.unmodifiable(_products);
  double get salesTotal => _salesTotal;
  int get currentCartCount => _currentCartCount;

  int get totalStock => _products.fold(
        0,
        (sum, product) => sum + product.stock,
      );

  void addProduct(ProductModel product) {
    final index = _products.length;

    final barcode = product.barcode ??
        _barcodeService.generateClothingBarcode(
          productIndex: index,
          categoryCode: product.categoryCode,
          colorCode: product.colorCode,
          sizeCode: product.sizeCode,
        );

    _products.add(
      product.copyWith(barcode: barcode),
    );

    notifyListeners();
  }

  void updateProduct(int index, ProductModel product) {
    _products[index] = product;
    notifyListeners();
  }

  void updateProductBarcode(int index, String barcode) {
    _products[index] = _products[index].copyWith(barcode: barcode);
    notifyListeners();
  }

  void deleteProduct(int index) {
    _products.removeAt(index);
    notifyListeners();
  }

  void incrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index == -1) return;

    final product = _products[index];
    _products[index] = product.copyWith(
      stock: product.stock + quantity,
    );

    notifyListeners();
  }

  void decrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index == -1) return;

    final product = _products[index];
    _products[index] = product.copyWith(
      stock: (product.stock - quantity).clamp(0, product.stock).toInt(),
    );

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