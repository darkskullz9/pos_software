class ProductModel {
  final int? id;
  final String name;
  final String? brand;
  final double price;
  final int stock;
  final String? barcode;
  final int categoryCode;
  final int? colorCode;
  final int? sizeCode;

  const ProductModel({
    this.id,
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
    int? id,
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
      id: id ?? this.id,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'stock': stock,
      'barcode': barcode,
      'category_code': categoryCode,
      'color_code': colorCode,
      'size_code': sizeCode,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      barcode: map['barcode'] as String?,
      categoryCode: map['category_code'] as int,
      colorCode: map['color_code'] as int?,
      sizeCode: map['size_code'] as int?,
    );
  }
}