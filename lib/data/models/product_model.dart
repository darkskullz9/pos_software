class ProductModel {
  final String name;
  final double price;
  final int stock;
  final String? barcode;

  final int categoryCode;
  final int colorCode;
  final int sizeCode;

  const ProductModel({
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    required this.categoryCode,
    required this.colorCode,
    required this.sizeCode,
  });

  ProductModel copyWith({
    String? name,
    double? price,
    int? stock,
    String? barcode,
    int? categoryCode,
    int? colorCode,
    int? sizeCode,
  }) {
    return ProductModel(
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      categoryCode: categoryCode ?? this.categoryCode,
      colorCode: colorCode ?? this.colorCode,
      sizeCode: sizeCode ?? this.sizeCode,
    );
  }
}