import 'package:flutter/material.dart';

class AppSettingsModel {
  final String storeName;
  final String currency;
  final double defaultTaxRate;

  final String defaultPaymentMethod;
  final bool confirmBeforeCheckout;
  final bool preventNegativeStock;

  final int lowStockThreshold;
  final bool autoGenerateBarcode;
  final int storeCode;

  final int defaultLabelQuantity;
  final String receiptFooter;
  final String barcodeFormat;

  final ThemeMode themeMode;

  const AppSettingsModel({
    required this.storeName,
    required this.currency,
    required this.defaultTaxRate,
    required this.defaultPaymentMethod,
    required this.confirmBeforeCheckout,
    required this.preventNegativeStock,
    required this.lowStockThreshold,
    required this.autoGenerateBarcode,
    required this.storeCode,
    required this.defaultLabelQuantity,
    required this.receiptFooter,
    required this.barcodeFormat,
    required this.themeMode,
  });

  factory AppSettingsModel.defaults() {
    return const AppSettingsModel(
      storeName: 'POS Software',
      currency: 'EUR',
      defaultTaxRate: 20.0,
      defaultPaymentMethod: 'Carte bancaire',
      confirmBeforeCheckout: true,
      preventNegativeStock: true,
      lowStockThreshold: 3,
      autoGenerateBarcode: true,
      storeCode: 1,
      defaultLabelQuantity: 1,
      receiptFooter: 'Merci pour votre achat.',
      barcodeFormat: 'EAN-13',
      themeMode: ThemeMode.system,
    );
  }

  AppSettingsModel copyWith({
    String? storeName,
    String? currency,
    double? defaultTaxRate,
    String? defaultPaymentMethod,
    bool? confirmBeforeCheckout,
    bool? preventNegativeStock,
    int? lowStockThreshold,
    bool? autoGenerateBarcode,
    int? storeCode,
    int? defaultLabelQuantity,
    String? receiptFooter,
    String? barcodeFormat,
    ThemeMode? themeMode,
  }) {
    return AppSettingsModel(
      storeName: storeName ?? this.storeName,
      currency: currency ?? this.currency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      confirmBeforeCheckout:
          confirmBeforeCheckout ?? this.confirmBeforeCheckout,
      preventNegativeStock: preventNegativeStock ?? this.preventNegativeStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      autoGenerateBarcode: autoGenerateBarcode ?? this.autoGenerateBarcode,
      storeCode: storeCode ?? this.storeCode,
      defaultLabelQuantity:
          defaultLabelQuantity ?? this.defaultLabelQuantity,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, String> toSettingsMap() {
    return {
      'storeName': storeName,
      'currency': currency,
      'defaultTaxRate': defaultTaxRate.toString(),
      'defaultPaymentMethod': defaultPaymentMethod,
      'confirmBeforeCheckout': confirmBeforeCheckout.toString(),
      'preventNegativeStock': preventNegativeStock.toString(),
      'lowStockThreshold': lowStockThreshold.toString(),
      'autoGenerateBarcode': autoGenerateBarcode.toString(),
      'storeCode': storeCode.toString(),
      'defaultLabelQuantity': defaultLabelQuantity.toString(),
      'receiptFooter': receiptFooter,
      'barcodeFormat': barcodeFormat,
      'themeMode': themeMode.name,
    };
  }

  factory AppSettingsModel.fromSettingsMap(Map<String, String> map) {
    final defaults = AppSettingsModel.defaults();

    return AppSettingsModel(
      storeName: map['storeName'] ?? defaults.storeName,
      currency: map['currency'] ?? defaults.currency,
      defaultTaxRate:
          double.tryParse(map['defaultTaxRate'] ?? '') ??
              defaults.defaultTaxRate,
      defaultPaymentMethod:
          map['defaultPaymentMethod'] ?? defaults.defaultPaymentMethod,
      confirmBeforeCheckout:
          _parseBool(map['confirmBeforeCheckout']) ??
              defaults.confirmBeforeCheckout,
      preventNegativeStock:
          _parseBool(map['preventNegativeStock']) ??
              defaults.preventNegativeStock,
      lowStockThreshold:
          int.tryParse(map['lowStockThreshold'] ?? '') ??
              defaults.lowStockThreshold,
      autoGenerateBarcode:
          _parseBool(map['autoGenerateBarcode']) ??
              defaults.autoGenerateBarcode,
      storeCode: int.tryParse(map['storeCode'] ?? '') ?? defaults.storeCode,
      defaultLabelQuantity:
          int.tryParse(map['defaultLabelQuantity'] ?? '') ??
              defaults.defaultLabelQuantity,
      receiptFooter: map['receiptFooter'] ?? defaults.receiptFooter,
      barcodeFormat: map['barcodeFormat'] ?? defaults.barcodeFormat,
      themeMode: _parseThemeMode(map['themeMode']) ?? defaults.themeMode,
    );
  }

  static bool? _parseBool(String? value) {
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  static ThemeMode? _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}