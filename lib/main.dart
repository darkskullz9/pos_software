import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/services/barcode_service.dart';
import 'data/services/product_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final productService = ProductService();
  final barcodeService = BarcodeService();

  runApp(
    CaisseApp(
      productService: productService,
      barcodeService: barcodeService,
    ),
  );
}