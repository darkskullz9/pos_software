import '../models/product_model.dart';
import 'barcode_service.dart';

class ProductService {
  final _barcodeService = BarcodeService();

  final List<ProductModel> _products = [];

  List<ProductModel> get products => _products;

  void addProduct(ProductModel product) {
    final index = _products.length;

    final barcode = product.barcode ?? _barcodeService.generateClothingBarcode(
      productIndex: index,
      categoryCode: product.categoryCode,
      colorCode: product.colorCode,
      sizeCode: product.sizeCode,
    );

    _products.add(
      product.copyWith(barcode: barcode),
    );
  }

  void updateProduct(int index, ProductModel product) {
    _products[index] = product;
  }

  void updateProductBarcode(int index, String barcode) {
    _products[index] = _products[index].copyWith(barcode: barcode);
  }

  void deleteProduct(int index) {
    _products.removeAt(index);
  }

  void incrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index == -1) return;

    final p = _products[index];
    _products[index] = p.copyWith(
      stock: p.stock + quantity,
    );
  }

  void decrementStock(String productName, int quantity) {
    final index = _products.indexWhere((p) => p.name == productName);
    if(index == -1) return;

    final p = _products[index];
    _products[index] = p.copyWith(
      stock: (p.stock - quantity).clamp(0, p.stock).toInt(),
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