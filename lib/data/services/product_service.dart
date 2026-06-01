import '../models/product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final List<ProductModel> _products = [];

  List<ProductModel> get products => List.unmodifiable(_products);

  void addProduct(ProductModel product) {
    _products.add(product);
  }

  void updateProduct(int index, ProductModel product) {
    _products[index] = product;
  }

  void deleteProduct(int index) {
    _products.removeAt(index);
  }

  void incrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index == -1) return;

    final p = _products[index];
    _products[index] = ProductModel(
      name: p.name,
      price: p.price,
      stock: p.stock + quantity,
      barcode: p.barcode,
    );
  }

  void decrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if(index == -1) return;

    final p = _products[index];
    _products[index] = ProductModel(
      name: p.name,
      price: p.price,
      stock: (p.stock - quantity).clamp(0, p.stock),
      barcode: p.barcode,
    );
  }

  ProductModel? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch(_) {
      return null;
    }
  }

  List<ProductModel> search(String query) {
    if(query.trim().isEmpty) return List.unmodifiable(_products);
    return _products
      .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  }
}