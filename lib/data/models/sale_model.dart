class SaleModel {
  final int? id;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;

  const SaleModel({
    this.id,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
  });

  SaleModel copyWith({
    int? id,
    double? total,
    String? paymentMethod,
    DateTime? createdAt,
  }) {
    return SaleModel(
      id: id ?? this.id,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'total': total,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map['id'] as int?,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
