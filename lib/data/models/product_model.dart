class ProductModel {
  final String name;
  final String? brand;
  final double price;
  final int stock;
  final String? barcode;
  final int categoryCode;
  final int? colorCode;
  final int? sizeCode;

  const ProductModel({
    required this.name,
    this.brand,
    required this.price,
    required this.stock,
    this.barcode,
    required this.categoryCode,
    this.colorCode,
    this.sizeCode,
  });

  ProductModel copyWith({
    String? name,
    String? brand,
    double? price,
    int? stock,
    String? barcode,
    int? categoryCode,
    int? colorCode,
    int? sizeCode,
  }) {
    return ProductModel(
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      categoryCode: categoryCode ?? this.categoryCode,
      colorCode: colorCode ?? this.colorCode,
      sizeCode: sizeCode ?? this.sizeCode,
    );
  }
}