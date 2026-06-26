import 'package:flutter/material.dart';

import '../core/widgets/app_shell.dart';
import '../data/services/barcode_service.dart';
import '../data/services/product_service.dart';
import '../data/services/settings_service.dart';

class CaisseApp extends StatelessWidget {
  final ProductService productService;
  final BarcodeService barcodeService;
  final SettingsService settingsService;

  const CaisseApp({
    super.key,
    required this.productService,
    required this.barcodeService,
    required this.settingsService,
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
        settingsService: settingsService,
      ),
    );
  }
}
