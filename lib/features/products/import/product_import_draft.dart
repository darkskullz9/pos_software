class ProductImportDraft {
  final String rawLine;
  final String name;
  final String type;
  final String category;
  final String subCategory;
  final String brand;
  final String color;
  final String size;
  final String location;
  final String description;
  final int stock;
  final double price;

  const ProductImportDraft({
    required this.rawLine,
    required this.name,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.brand,
    required this.color,
    required this.size,
    required this.location,
    required this.description,
    required this.stock,
    required this.price,
  });

  bool get needsReview {
    return type == 'Article' ||
        color == 'Non renseignée' ||
        size == 'Non renseignée' ||
        price <= 0;
  }

  ProductImportDraft copyWith({
    String? rawLine,
    String? name,
    String? type,
    String? category,
    String? subCategory,
    String? brand,
    String? color,
    String? size,
    String? location,
    String? description,
    int? stock,
    double? price,
  }) {
    return ProductImportDraft(
      rawLine: rawLine ?? this.rawLine,
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      size: size ?? this.size,
      location: location ?? this.location,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      price: price ?? this.price,
    );
  }
}
