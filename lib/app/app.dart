import 'package:flutter/material.dart';

import '../core/widgets/app_shell.dart';
import '../data/services/barcode_service.dart';
import '../data/services/product_service.dart';

class CaisseApp extends StatelessWidget {
  final ProductService productService;
  final BarcodeService barcodeService;

  const CaisseApp({
    super.key,
    required this.productService,
    required this.barcodeService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Software',
      theme: ThemeData(
        useMaterial3: true,
      ), 

      home: AppShell(
        productService: productService,
        barcodeService: barcodeService,
      ),
    );
  }
}