import 'product_import_draft.dart';

class ProductImportParser {
  final List<String> productTypes;
  final List<String> brands;
  final List<String> colors;
  final List<String> locations;
  final double defaultPrice;

  const ProductImportParser({
    required this.productTypes,
    required this.brands,
    required this.colors,
    required this.locations,
    this.defaultPrice = 0,
  });

  static const Map<String, String> _brandAliases = {
    '3 suisses': '3 Suisses',
    'air spire': 'Airspire',
    'airspire': 'Airspire',
    'assos design': 'ASOS DESIGN',
    'asos design': 'ASOS DESIGN',
    'atlasformen': 'Atlas For Men',
    'cache cache': 'Cache Cache',
    'camayeu': 'Camaïeu',
    'camayeru': 'Camaïeu',
    'camaieu': 'Camaïeu',
    'c&a': 'C&A',
    'coca cola': 'Coca-Cola',
    'dont call me': 'Don\'t Call Me',
    'don\'t call me': 'Don\'t Call Me',
    'eden rock': 'Eden Rock',
    'fb sister': 'FB Sister',
    'fashion private company women': 'Fashion Private Company Women',
    'gemo': 'Gémo',
    'gémo': 'Gémo',
    'h&m': 'H&M',
    'harris and lewis dept': 'Harris & Lewis Dept',
    'heritage': 'Héritage',
    'héritage': 'Héritage',
    'in extenso': 'In Extenso',
    'inextenso': 'In Extenso',
    'jennufer': 'Jennyfer',
    'jennyfer': 'Jennyfer',
    'la fee maraboutee': 'La Fée Maraboutée',
    'la fée maraboutée': 'La Fée Maraboutée',
    'little marcel': 'Little Marcel',
    'losc': 'LOSC',
    'maison scotch': 'Maison Scotch',
    'msmode': 'MS Mode',
    'naf naf': 'Naf Naf',
    'nasa': 'NASA',
    'new balance': 'New Balance',
    'only': 'ONLY',
    'women only': 'ONLY',
    'pas de marque': 'Sans marque',
    'pink-berry': 'Pink Berry',
    'pink berry': 'Pink Berry',
    'pretty little thing': 'PrettyLittleThing',
    'prettylittlething': 'PrettyLittleThing',
    'pull and bear': 'Pull&Bear',
    'pull&bear': 'Pull&Bear',
    'qualite or': 'Qualité Or',
    'qualité or': 'Qualité Or',
    'redoute': 'La Redoute',
    'ripcurl': 'Rip Curl',
    'rip curl': 'Rip Curl',
    'sans marque': 'Sans marque',
    'star war': 'Star Wars',
    'star wars': 'Star Wars',
    'the perfect partner': 'The Perfect Partner',
    'tommy hilfiger': 'Tommy Hilfiger',
    'up2glide': 'Up2Glide',
    'vero moda': 'Vero Moda',
  };

  static const Map<String, String> _typeAliases = {
    'cache cou': 'Cache-cou',
    'cache-cou': 'Cache-cou',
    'echarpe': 'Écharpe',
    'écharpe': 'Écharpe',
    'tshirt': 'T-shirt',
    'tee-shirt': 'T-shirt',
    't-shirt': 'T-shirt',
  };

  List<ProductImportDraft> parse(String rawText) {
    final drafts = <ProductImportDraft>[];
    var currentLocation = 'Non renseigné';

    final lines = rawText.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line.isEmpty) continue;
      if (_isSeparator(line)) continue;

      if (_isLocationHeader(line)) {
        currentLocation = _normalizeLocation(line);
        continue;
      }

      if (_isCaseLine(line)) {
        drafts.addAll(_parseCaseLine(line, currentLocation));
        continue;
      }

      drafts.add(_parseProductLine(line, currentLocation));
    }

    return drafts;
  }

  bool _isSeparator(String line) {
    return RegExp(r'^_+$').hasMatch(line);
  }

  bool _isLocationHeader(String line) {
    final normalized = _normalize(line);

    if (normalized.startsWith('etagere ')) return true;
    if (normalized.startsWith('rond ')) return true;
    if (normalized.startsWith('carre ')) return true;
    if (normalized == 'etagere pantalon') return true;

    return locations.any((location) => _normalize(location) == normalized);
  }

  String _normalizeLocation(String line) {
    final normalizedLine = _normalize(line);

    for (final location in locations) {
      if (_normalize(location) == normalizedLine) {
        return location;
      }
    }

    if (normalizedLine == 'etagere pantalon') {
      return 'Étagère pantalon';
    }

    return line.trim();
  }

  bool _isCaseLine(String line) {
    return RegExp(r'^case\s*\d+\s*:', caseSensitive: false).hasMatch(line);
  }

  List<ProductImportDraft> _parseCaseLine(String line, String currentLocation) {
    final match = RegExp(
      r'^Case\s*(\d+)\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(line);

    if (match == null) {
      return [_parseProductLine(line, currentLocation)];
    }

    final caseNumber = match.group(1)!;
    final content = match.group(2)!;
    final caseLocation = '$currentLocation - Case $caseNumber';

    final parts = content.split(',');
    final drafts = <ProductImportDraft>[];

    String? inheritedType;

    for (final part in parts) {
      var cleanPart = part.trim();
      if (cleanPart.isEmpty) continue;

      final detectedType = _extractType(cleanPart);

      if (detectedType != 'Article') {
        inheritedType = detectedType;
      } else if (inheritedType != null) {
        cleanPart = '$inheritedType $cleanPart';
      }

      drafts.add(_parseProductLine(cleanPart, caseLocation));
    }

    return drafts;
  }

  ProductImportDraft _parseProductLine(String line, String location) {
    final quantityResult = _extractQuantity(line);
    final cleanLine = quantityResult.cleanLine;
    final stock = quantityResult.quantity;

    final type = _extractType(cleanLine);
    final brand = _extractBrand(cleanLine);
    final color = _extractColor(cleanLine);
    final category = _categoryFromType(type);
    final subCategory = _subCategoryFromType(type);
    final description = _extractDescription(
      cleanLine: cleanLine,
      type: type,
      brand: brand,
      color: color,
    );

    return ProductImportDraft(
      rawLine: line,
      name: cleanLine,
      type: type,
      category: category,
      subCategory: subCategory,
      brand: brand,
      color: color,
      size: 'Non renseignée',
      location: location,
      description: description,
      stock: stock,
      price: _defaultPriceForType(type),
    );
  }

  _QuantityResult _extractQuantity(String line) {
    final match = RegExp(
      r'(?:\(\s*x\s*(\d+)\s*\)|x\s*(\d+))$',
      caseSensitive: false,
    ).firstMatch(line);

    if (match == null) {
      return _QuantityResult(cleanLine: line.trim(), quantity: 1);
    }

    final quantityText = match.group(1) ?? match.group(2);
    final quantity = int.tryParse(quantityText ?? '') ?? 1;
    final cleanLine = line.substring(0, match.start).trim();

    return _QuantityResult(cleanLine: cleanLine, quantity: quantity);
  }

  String _extractType(String line) {
    final normalizedLine = _normalize(line);

    final aliasEntries = _typeAliases.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in aliasEntries) {
      final alias = _normalize(entry.key);

      if (normalizedLine.startsWith(alias)) {
        return entry.value;
      }
    }

    final sortedTypes = List<String>.from(productTypes)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final type in sortedTypes) {
      if (normalizedLine.startsWith(_normalize(type))) {
        return type;
      }
    }

    return 'Article';
  }

  String _extractBrand(String line) {
    final normalizedLine = _normalize(line);

    if (normalizedLine.contains('sans marque') ||
        normalizedLine.contains('pas de marque')) {
      return 'Sans marque';
    }

    final aliasEntries = _brandAliases.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in aliasEntries) {
      final alias = _normalize(entry.key);

      if (normalizedLine.endsWith(alias) ||
          _containsPhrase(normalizedLine, alias)) {
        return entry.value;
      }
    }

    final sortedBrands = List<String>.from(brands)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final brand in sortedBrands) {
      final normalizedBrand = _normalize(brand);

      if (normalizedLine.endsWith(normalizedBrand) ||
          _containsPhrase(normalizedLine, normalizedBrand)) {
        return brand;
      }
    }

    return 'Sans marque';
  }

  String _extractColor(String line) {
    final normalizedLine = _normalize(line);
    final detectedColors = <String>[];

    final sortedColors = List<String>.from(colors)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final color in sortedColors) {
      if (_normalize(color) == 'non renseignee') continue;

      final normalizedColor = _normalize(color);

      if (_containsWord(normalizedLine, normalizedColor)) {
        final displayColor = _normalizeDisplayColor(color);

        if (!detectedColors.contains(displayColor)) {
          detectedColors.add(displayColor);
        }
      }
    }

    if (detectedColors.isEmpty) {
      return 'Non renseignée';
    }

    return detectedColors.join('/');
  }

  String _extractDescription({
    required String cleanLine,
    required String type,
    required String brand,
    required String color,
  }) {
    var description = cleanLine;

    if (type != 'Article') {
      description = description.replaceFirst(
        RegExp(RegExp.escape(type), caseSensitive: false),
        '',
      );
    }

    if (brand != 'Sans marque') {
      description = description.replaceAll(
        RegExp(RegExp.escape(brand), caseSensitive: false),
        '',
      );
    }

    description = description
        .replaceAll(RegExp(r'sans marque', caseSensitive: false), '')
        .replaceAll(RegExp(r'pas de marque', caseSensitive: false), '');

    for (final colorPart in color.split('/')) {
      description = description.replaceAll(
        RegExp(RegExp.escape(colorPart), caseSensitive: false),
        '',
      );
    }

    description = description
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (description.isEmpty) {
      return '-';
    }

    return description;
  }

  String _categoryFromType(String type) {
    switch (type) {
      case 'Écharpe':
      case 'Cache-cou':
        return 'Accessoires';
      default:
        return 'Vêtements';
    }
  }

  String _subCategoryFromType(String type) {
    switch (type) {
      case 'Pantalon':
      case 'Short':
      case 'Jupe':
        return 'Bas';

      case 'T-shirt':
      case 'Débardeur':
      case 'Brassière':
      case 'Chemise':
      case 'Polo':
      case 'Haut':
      case 'Pull':
      case 'Gilet':
        return 'Hauts';

      case 'Robe':
        return 'Robes';

      case 'Veste':
      case 'Manteau':
        return 'Vestes & manteaux';

      case 'Ensemble femme':
      case 'Ensemble enfant fille':
        return 'Ensembles';

      case 'Écharpe':
      case 'Cache-cou':
        return 'Accessoires';

      default:
        return 'Autres';
    }
  }

  double _defaultPriceForType(String type) {
    if (defaultPrice > 0) {
      return defaultPrice;
    }

    switch (type) {
      case 'T-shirt':
      case 'Débardeur':
      case 'Haut':
        return 2.0;

      case 'Chemise':
      case 'Polo':
      case 'Jupe':
      case 'Short':
        return 3.0;

      case 'Pull':
      case 'Gilet':
      case 'Pantalon':
        return 4.0;

      case 'Robe':
      case 'Veste':
      case 'Manteau':
        return 5.0;

      case 'Écharpe':
      case 'Cache-cou':
        return 1.0;

      case 'Ensemble femme':
      case 'Ensemble enfant fille':
        return 6.0;

      default:
        return 0.0;
    }
  }

  String _normalizeDisplayColor(String color) {
    switch (_normalize(color)) {
      case 'creme':
        return 'crème';
      default:
        return color.toLowerCase();
    }
  }

  bool _containsPhrase(String text, String phrase) {
    return text.contains(phrase);
  }

  bool _containsWord(String text, String word) {
    final pattern = RegExp(
      '(^|[^a-z0-9])${RegExp.escape(word)}([^a-z0-9]|\$)',
      caseSensitive: false,
    );

    return pattern.hasMatch(text);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll('à', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ÿ', 'y')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _QuantityResult {
  final String cleanLine;
  final int quantity;

  const _QuantityResult({required this.cleanLine, required this.quantity});
}
