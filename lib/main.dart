import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';
import 'data/services/barcode_service.dart';
import 'data/services/product_service.dart';
import 'data/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final productService = ProductService();
  final barcodeService = BarcodeService();
  final settingsService = SettingsService();

  runApp(
    CaisseApp(
      productService: productService,
      barcodeService: barcodeService,
      settingsService: settingsService,
    ),
  );
}
