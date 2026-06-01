class ProductModel {
  final String name;
  final double price;
  final int stock;
  final String? barcode;

  const ProductModel({
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
  });
}