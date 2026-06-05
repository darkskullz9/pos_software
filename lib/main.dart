import 'package:flutter/material.dart';
import 'app/app.dart';
import 'data/services/product_service.dart';
import 'data/services/barcode_service.dart';

void main() {
  final productService = ProductService();
  final barcodeService = BarcodeService();

  runApp(
    CaisseApp(productService: productService, barcodeService: barcodeService),
  );
}
