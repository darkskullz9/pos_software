import 'package:flutter/material.dart';

import 'dart:convert';

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

  final List<String> productTypes;
  final List<String> subCategories;
  final List<String> brands;
  final List<String> colors;
  final List<String> sizes;
  final List<String> locations;

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
    required this.productTypes,
    required this.subCategories,
    required this.brands,
    required this.colors,
    required this.sizes,
    required this.locations,
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
      productTypes: [
        'Manteau',
        'Veste',
        'Pull',
        'Gilet',
        'T-shirt',
        'Débardeur',
        'Brassière',
        'Haut',
        'Chemise',
        'Polo',
        'Pantalon',
        'Short',
        'Jupe',
        'Robe',
        'Ensemble femme',
        'Ensemble enfant fille',
        'Écharpe',
        'Cache-cou',
      ],

      subCategories: [
        'Hauts',
        'Bas',
        'Robes',
        'Vestes & manteaux',
        'Ensembles',
        'Accessoires',
        'Autres',
      ],

      brands: [
        'Sans marque',
        '3 Suisses',
        'AC Belle',
        'Actuelle',
        'Ada Gatti',
        'Adidas',
        'Afibel',
        'Airspire',
        'Alain Manoukian',
        'Apricot',
        'Armand Thiery',
        'ASOS DESIGN',
        'Astuces',
        'Atlas For Men',
        'Atmosphere',
        'Avt Worker Jean',
        'B. News',
        'Bershka',
        'Bizzbee',
        'Blåkläder',
        'Bonobo',
        'Boohoo',
        'Brice',
        'Burton',
        'C&A',
        'Cache Cache',
        'Camaïeu',
        'Canda',
        'Caroll',
        'Celio',
        'Cecilia Classics',
        'Chipie',
        'Christine Laure',
        'Collusion',
        'Colorine',
        'Cop Copine',
        'Coca-Cola',
        'DDP',
        'Décade',
        'Deeluxe',
        'Dele',
        'Denim Co',
        'Diplodocus',
        'Domyos',
        'Dorotennis',
        'Don\'t Call Me',
        'Eden Rock',
        'Édéis',
        'Emoi',
        'Energetics',
        'Esprit',
        'Etirel',
        'Exposure',
        'Fashion Private Company Women',
        'FB Sister',
        'Ferrache',
        'Firefly',
        'Firetrap',
        'French Collection',
        'Gémo',
        'Guy Torphi',
        'H&M',
        'Handerafled',
        'Harris & Lewis Dept',
        'Héritage',
        'Hollister',
        'Humility',
        'Ici et Maintenant',
        'In Extenso',
        'It Hippie',
        'JHK',
        'Jennyfer',
        'Jules',
        'Kiabi',
        'La Fée Maraboutée',
        'La Redoute',
        'Lady Belle',
        'Let Me Try',
        'Little Marcel',
        'Livergy',
        'LLDR',
        'LOSC',
        'Maison Scotch',
        'Man Tobas',
        'Millenium',
        'MNG',
        'Modap Nhan',
        'Molly Bracken',
        'Monoprix',
        'MS Mode',
        'Naf Naf',
        'NASA',
        'New Balance',
        'Next',
        'NX Sport',
        'Odemai',
        'Olivier de Breuil',
        'ONLY',
        'Patrice Bréal',
        'Phildar',
        'Pierre Cardin',
        'Pimkie',
        'Pink Berry',
        'Please',
        'PrettyLittleThing',
        'Primark',
        'Promod',
        'Pull&Bear',
        'Qualité Or',
        'Rip Curl',
        'Riu',
        'RS Wear',
        'Savvy',
        'Shein',
        'Spot',
        'Squitos',
        'Star Wars',
        'T-Traxx',
        'The Perfect Partner',
        'Tibet',
        'Tissaia',
        'Tommy Hilfiger',
        'True Rise',
        'Up2Glide',
        'Urban',
        'Vero Moda',
        'Vortex',
        'Wang Li',
        'Yale',
        'Yessica',
        'Zeeman',
        'Zara',
      ],

      colors: [
        'Non renseignée',
        'noir',
        'blanc',
        'gris',
        'beige',
        'orange',
        'rouge',
        'violet',
        'marron',
        'bleu',
        'vert',
        'cyan',
        'rose',
        'jaune',
        'crème',
        'jean',
        'multicolore',
      ],
      sizes: [
        'Non renseignée',
        'Unique',
        'XS',
        'S',
        'M',
        'L',
        'XL',
        'XXL',
        '34',
        '36',
        '38',
        '40',
        '42',
        '44',
        '46',
        '48',
      ],

      locations: [
        'Étagère 1',
        'Étagère 2',
        'Rond 1',
        'Rond 2',
        'Carré 1',
        'Carré 2',
        'Étagère pantalon - Case 1',
        'Étagère pantalon - Case 2',
        'Étagère pantalon - Case 3',
        'Étagère pantalon - Case 4',
        'Étagère pantalon - Case 5',
        'Étagère pantalon - Case 6',
        'Étagère pantalon - Case 7',
        'Étagère pantalon - Case 8',
        'Étagère pantalon - Case 9',
        'Étagère pantalon - Case 10',
        'Étagère pantalon - Case 11',
        'Étagère pantalon - Case 12',
      ],
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
    List<String>? productTypes,
    List<String>? subCategories,
    List<String>? brands,
    List<String>? colors,
    List<String>? sizes,
    List<String>? locations,
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
      defaultLabelQuantity: defaultLabelQuantity ?? this.defaultLabelQuantity,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      themeMode: themeMode ?? this.themeMode,
      productTypes: productTypes ?? this.productTypes,
      subCategories: subCategories ?? this.subCategories,
      brands: brands ?? this.brands,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      locations: locations ?? this.locations,
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
      'productTypes': jsonEncode(productTypes),
      'subCategories': jsonEncode(subCategories),
      'brands': jsonEncode(brands),
      'colors': jsonEncode(colors),
      'sizes': jsonEncode(sizes),
      'locations': jsonEncode(locations),
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
      productTypes: _parseStringList(
        map['productTypes'],
        defaults.productTypes,
      ),
      subCategories: _parseStringList(
        map['subCategories'],
        defaults.subCategories,
      ),
      brands: _parseStringList(map['brands'], defaults.brands),
      colors: _parseStringList(map['colors'], defaults.colors),
      sizes: _parseStringList(map['sizes'], defaults.sizes),
      locations: _parseStringList(map['locations'], defaults.locations),
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

  static List<String> _parseStringList(String? value, List<String> fallback) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! List) {
        return fallback;
      }

      final list = decoded
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();

      if (list.isEmpty) {
        return fallback;
      }

      list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return list;
    } catch (_) {
      return fallback;
    }
  }
}
