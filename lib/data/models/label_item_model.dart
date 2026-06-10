import 'product_model.dart';

class LabelItemModel {
  final ProductModel product;
  final int quantity;

  const LabelItemModel({
    required this.product,
    required this.quantity,
  });
}