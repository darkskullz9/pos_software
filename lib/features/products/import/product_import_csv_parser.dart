import 'product_import_draft.dart';

class ProductImportCsvParser {
  final List<String> productTypes;
  final List<String> brands;
  final List<String> colors;
  final List<String> locations;
  final double defaultPrice;

  ProductImportCsvParser({
    required this.productTypes,
    required this.brands,
    required this.colors,
    required this.locations,
    this.defaultPrice = 0,
  });

  static const String unknownValue = 'Non renseignée';

  List<ProductImportDraft> parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final separator = _detectSeparator(lines.first);
    final headers = _parseCsvLine(
      lines.first,
      separator,
    ).map(_normalizeHeader).toList();

    final drafts = <ProductImportDraft>[];

    for (var i = 1; i < lines.length; i++) {
      final rawLine = lines[i];
      final columns = _parseCsvLine(rawLine, separator);

      final draft = _parseRow(
        rawLine: rawLine,
        headers: headers,
        columns: columns,
      );

      if (draft == null) continue;

      drafts.add(draft);
    }

    return _mergeSimilarDrafts(drafts);
  }

  ProductImportDraft? _parseRow({
    required String rawLine,
    required List<String> headers,
    required List<String> columns,
  }) {
    String field(List<String> names) {
      final normalizedNames = names.map(_normalizeHeader).toSet();

      for (var i = 0; i < headers.length; i++) {
        if (!normalizedNames.contains(headers[i])) continue;
        if (i >= columns.length) return '';

        return columns[i].trim();
      }

      return '';
    }

    final typeInput = field([
      'type',
      'article',
      'product_type',
      'categorie_produit',
      'catégorie_produit',
    ]);

    final nameInput = field([
      'name',
      'nom',
      'produit',
      'product',
      'article_name',
      'nom_produit',
    ]);

    final brandInput = field(['brand', 'marque']);

    final colorInput = field(['color', 'couleur']);

    final sizeInput = field(['size', 'taille']);

    final stockInput = field([
      'stock',
      'quantity',
      'quantite',
      'quantité',
      'qty',
      'qte',
      'qté',
    ]);

    final priceInput = field(['price', 'prix', 'tarif']);

    final patternInput = field([
      'pattern',
      'motif',
      'style',
      'detail',
      'details',
      'détail',
      'détails',
    ]);

    final locationInput = field([
      'location',
      'emplacement',
      'zone',
      'case',
      'rayon',
    ]);

    final descriptionInput = field(['description', 'desc', 'note', 'notes']);

    if (typeInput.trim().isEmpty && nameInput.trim().isEmpty) {
      return null;
    }

    final brand = _canonicalBrand(brandInput);
    final color = _canonicalColor(colorInput);
    final size = _canonicalSize(sizeInput);

    final detectedTypeFromInput = _canonicalType(typeInput);
    final detectedTypeFromName = _findProductTypeValue(nameInput);

    final type = detectedTypeFromInput != 'Article'
        ? detectedTypeFromInput
        : detectedTypeFromName ?? 'Article';

    final name = _buildProductName(
      type: type,
      explicitName: nameInput,
      pattern: patternInput,
      brand: brand,
      color: color,
      size: size,
    );

    final stock = _parseStock(stockInput);
    final price = _parsePrice(priceInput, type);
    final location = _canonicalLocation(locationInput);

    final category = _categoryForType(type);
    final subCategory = _subCategoryForType(type);

    final description = descriptionInput.trim().isNotEmpty
        ? descriptionInput.trim()
        : _buildDescription(
            type: type,
            brand: brand,
            color: color,
            size: size,
            location: location,
          );

    return ProductImportDraft(
      rawLine: rawLine,
      name: name,
      type: type,
      category: category,
      subCategory: subCategory,
      brand: brand,
      color: color,
      size: size,
      location: location,
      description: description,
      stock: stock,
      price: price,
    );
  }

  String _detectSeparator(String headerLine) {
    final separators = [';', ',', '\t'];
    var bestSeparator = ';';
    var bestCount = -1;

    for (final separator in separators) {
      final count = separator.allMatches(headerLine).length;

      if (count > bestCount) {
        bestCount = count;
        bestSeparator = separator;
      }
    }

    return bestSeparator;
  }

  List<String> _parseCsvLine(String line, String separator) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';

        if (inQuotes && nextIsQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }

        continue;
      }

      if (char == separator && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    values.add(buffer.toString().trim());

    return values;
  }

  String _canonicalType(String value) {
    final found = _findProductTypeValue(value);

    return found ?? 'Article';
  }

  String? _findProductTypeValue(String value) {
    final candidates = <String, String>{};

    for (final type in _defaultProductTypes) {
      candidates[type] = type;
    }

    for (final type in productTypes) {
      if (type.trim().isNotEmpty) {
        candidates[type.trim()] = _capitalizeWords(type.trim());
      }
    }

    candidates.addAll({
      'tee shirt': 'T-shirt',
      'tee-shirt': 'T-shirt',
      'tshirt': 'T-shirt',
      't-shirt': 'T-shirt',
      'pull': 'Pull',
      'sweat': 'Pull',
      'hoodie': 'Pull',
      'pantalon': 'Pantalon',
      'pant': 'Pantalon',
      'jean': 'Pantalon',
      'jeans': 'Pantalon',
      'cargo': 'Pantalon',
      'robe': 'Robe',
      'jupe': 'Jupe',
      'short': 'Short',
      'chemise': 'Chemise',
      'polo': 'Polo',
      'veste': 'Veste',
      'manteau': 'Manteau',
      'gilet': 'Gilet',
      'haut': 'Haut',
      'top': 'Haut',
      'body': 'Body',
      'ensemble': 'Ensemble',
      'ensembles': 'Ensemble',
      'echarpe': 'Écharpe',
      'écharpe': 'Écharpe',
      'cache cou': 'Cache-cou',
      'cache-cou': 'Cache-cou',
      'bonnet': 'Bonnet',
      'casquette': 'Casquette',
    });

    return _findCandidate(value, candidates);
  }

  String _canonicalBrand(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return 'Sans marque';

    final candidates = <String, String>{};

    for (final brand in brands) {
      if (brand.trim().isNotEmpty) {
        candidates[brand.trim()] = _normalizeBrandName(brand.trim());
      }
    }

    candidates.addAll({
      'camayeu': 'Camaïeu',
      'camayeru': 'Camaïeu',
      'camaieu': 'Camaïeu',
      'cache cache': 'Cache Cache',
      'cache-cache': 'Cache Cache',
      'asos': 'ASOS',
      'assos': 'ASOS',
      'asos design': 'ASOS DESIGN',
      'women only': 'Women Only',
      'only': 'Only',
      'zara': 'Zara',
      'h&m': 'H&M',
      'hm': 'H&M',
      'nike': 'Nike',
      'adidas': 'Adidas',
      'puma': 'Puma',
      'reebok': 'Reebok',
      'jennyfer': 'Jennyfer',
      'kiabi': 'Kiabi',
      'shein': 'Shein',
      'bershka': 'Bershka',
      'stradivarius': 'Stradivarius',
      'pull and bear': 'Pull&Bear',
      'pull&bear': 'Pull&Bear',
    });

    final found = _findCandidate(trimmed, candidates);

    return found ?? _normalizeBrandName(trimmed);
  }

  String _canonicalColor(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return unknownValue;

    final candidates = <String, String>{};

    for (final color in _defaultColors) {
      candidates[color] = color;
    }

    for (final color in colors) {
      if (color.trim().isNotEmpty) {
        candidates[color.trim()] = _capitalizeWords(color.trim());
      }
    }

    candidates.addAll({
      'noir': 'Noir',
      'noire': 'Noir',
      'blanc': 'Blanc',
      'blanche': 'Blanc',
      'bleu': 'Bleu',
      'bleue': 'Bleu',
      'rouge': 'Rouge',
      'gris': 'Gris',
      'grise': 'Gris',
      'marron': 'Marron',
      'beige': 'Beige',
      'vert': 'Vert',
      'verte': 'Vert',
      'jaune': 'Jaune',
      'rose': 'Rose',
      'violet': 'Violet',
      'violette': 'Violet',
      'orange': 'Orange',
      'camel': 'Camel',
      'kaki': 'Kaki',
      'bordeaux': 'Bordeaux',
      'doré': 'Doré',
      'dore': 'Doré',
      'argenté': 'Argenté',
      'argente': 'Argenté',
      'multicolore': 'Multicolore',
    });

    final found = _findCandidate(trimmed, candidates);

    return found ?? _capitalizeWords(trimmed);
  }

  String _canonicalSize(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return unknownValue;

    final normalized = _normalize(trimmed);

    if (normalized == 'taille unique' || normalized == 'tu') {
      return 'TU';
    }

    return trimmed.toUpperCase();
  }

  String _canonicalLocation(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) return unknownValue;

    final normalized = _normalize(trimmed);

    for (final location in locations) {
      if (_normalize(location) == normalized) {
        return location.trim();
      }
    }

    return _capitalizeWords(trimmed);
  }

  int _parseStock(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return 1;

    final parsed = int.tryParse(cleaned.replaceAll(RegExp(r'[^0-9-]'), ''));

    if (parsed == null || parsed < 1) return 1;

    return parsed;
  }

  double _parsePrice(String value, String type) {
    final cleaned = value
        .trim()
        .replaceAll('€', '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'\s+'), '');

    final parsed = double.tryParse(cleaned);

    if (parsed != null && parsed > 0) {
      return parsed;
    }

    if (defaultPrice > 0) {
      return defaultPrice;
    }

    return _defaultPriceForType(type);
  }

  String _buildProductName({
    required String type,
    required String explicitName,
    required String pattern,
    required String brand,
    required String color,
    required String size,
  }) {
    var remaining = explicitName.trim();

    if (remaining.isEmpty) {
      remaining = pattern.trim();
    } else {
      remaining = _removeTextPart(remaining, type);

      if (brand != 'Sans marque') {
        remaining = _removeTextPart(remaining, brand);
      }

      if (color != unknownValue) {
        remaining = _removeTextPart(remaining, color);
      }

      if (size != unknownValue) {
        remaining = _removeTextPart(remaining, size);
      }

      if (pattern.trim().isNotEmpty &&
          !_normalize(remaining).contains(_normalize(pattern))) {
        remaining = '$remaining ${pattern.trim()}';
      }
    }

    remaining = _cleanupRemainingText(remaining);

    if (type == 'Article') {
      return remaining.isEmpty ? 'Article' : _capitalizeWords(remaining);
    }

    if (remaining.isEmpty) {
      return type;
    }

    if (_normalize(remaining) == _normalize(type)) {
      return type;
    }

    return '$type ${remaining.toLowerCase()}';
  }

  String _buildDescription({
    required String type,
    required String brand,
    required String color,
    required String size,
    required String location,
  }) {
    final parts = <String>[
      type,
      if (brand != 'Sans marque') brand,
      if (color != unknownValue) color,
      if (size != unknownValue) 'Taille $size',
      if (location != unknownValue) location,
    ];

    return parts.join(' - ');
  }

  List<ProductImportDraft> _mergeSimilarDrafts(
    List<ProductImportDraft> drafts,
  ) {
    final merged = <String, ProductImportDraft>{};

    for (final draft in drafts) {
      final key = [
        _normalize(draft.name),
        _normalize(draft.brand),
        _normalize(draft.color),
        _normalize(draft.size),
      ].join('|');

      final existing = merged[key];

      if (existing == null) {
        merged[key] = draft;
        continue;
      }

      merged[key] = ProductImportDraft(
        rawLine: '${existing.rawLine}\n${draft.rawLine}',
        name: existing.name,
        type: existing.type,
        category: existing.category,
        subCategory: existing.subCategory,
        brand: existing.brand,
        color: existing.color,
        size: existing.size,
        location: existing.location,
        description: existing.description,
        stock: existing.stock + draft.stock,
        price: existing.price,
      );
    }

    return merged.values.toList();
  }

  String? _findCandidate(String text, Map<String, String> candidates) {
    final normalizedText = _normalize(text);
    final entries = candidates.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in entries) {
      final normalizedCandidate = _normalize(entry.key);

      if (normalizedText == normalizedCandidate ||
          normalizedText.contains(' $normalizedCandidate ') ||
          normalizedText.startsWith('$normalizedCandidate ') ||
          normalizedText.endsWith(' $normalizedCandidate')) {
        return entry.value;
      }
    }

    return null;
  }

  String _removeTextPart(String source, String part) {
    if (part.trim().isEmpty) return source;

    return _normalizeSpaces(
      source.replaceAll(
        RegExp(RegExp.escape(part.trim()), caseSensitive: false),
        ' ',
      ),
    );
  }

  String _cleanupRemainingText(String value) {
    var result = _normalizeSpaces(value);

    result = result.replaceAll(RegExp(r'[:|/\\]+'), ' ');
    result = result.replaceAll(RegExp(r'\bde\b', caseSensitive: false), ' ');
    result = result.replaceAll(RegExp(r'\bdu\b', caseSensitive: false), ' ');
    result = result.replaceAll(RegExp(r'\bla\b', caseSensitive: false), ' ');
    result = result.replaceAll(RegExp(r'\ble\b', caseSensitive: false), ' ');
    result = result.replaceAll(RegExp(r'\bles\b', caseSensitive: false), ' ');

    return _normalizeSpaces(result);
  }

  String _categoryForType(String type) {
    if (_normalize(type) == 'article') return 'À vérifier';

    return 'Vêtement';
  }

  String _subCategoryForType(String type) {
    final normalized = _normalize(type);

    if (['pantalon', 'jupe', 'short'].contains(normalized)) {
      return 'Bas';
    }

    if ([
      'pull',
      't shirt',
      'tshirt',
      'chemise',
      'polo',
      'haut',
      'body',
      'gilet',
      'veste',
      'manteau',
    ].contains(normalized)) {
      return 'Haut';
    }

    if (['echarpe', 'cache cou', 'bonnet', 'casquette'].contains(normalized)) {
      return 'Accessoire';
    }

    if (normalized == 'robe') return 'Robe';
    if (normalized == 'ensemble') return 'Ensemble';

    return 'À vérifier';
  }

  double _defaultPriceForType(String type) {
    final normalized = _normalize(type);

    if (['echarpe', 'cache cou', 'bonnet', 'casquette'].contains(normalized)) {
      return 1;
    }

    if (['t shirt', 'tshirt', 'haut', 'body'].contains(normalized)) {
      return 2;
    }

    if (['chemise', 'polo', 'jupe', 'short'].contains(normalized)) {
      return 3;
    }

    if (['pull', 'gilet', 'pantalon'].contains(normalized)) {
      return 4;
    }

    if (['robe', 'veste', 'manteau'].contains(normalized)) {
      return 5;
    }

    if (normalized == 'ensemble') return 6;

    return 0;
  }

  String _normalizeBrandName(String value) {
    final trimmed = value.trim();

    if (trimmed.toUpperCase() == trimmed && trimmed.length <= 5) {
      return trimmed;
    }

    return _capitalizeWords(trimmed);
  }

  String _capitalizeWords(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) return part.toUpperCase();

          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _normalizeSpaces(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeHeader(String value) {
    return _normalize(value).replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String _normalize(String value) {
    return _normalizeSpaces(value)
        .toLowerCase()
        .replaceAll('œ', 'oe')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('í', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ó', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('&', ' and ')
        .replaceAll('-', ' ');
  }

  List<String> get _defaultProductTypes {
    return const [
      'T-shirt',
      'Pull',
      'Pantalon',
      'Robe',
      'Jupe',
      'Short',
      'Chemise',
      'Polo',
      'Veste',
      'Manteau',
      'Gilet',
      'Haut',
      'Body',
      'Ensemble',
      'Écharpe',
      'Cache-cou',
      'Bonnet',
      'Casquette',
    ];
  }

  List<String> get _defaultColors {
    return const [
      'Noir',
      'Blanc',
      'Bleu',
      'Rouge',
      'Gris',
      'Marron',
      'Beige',
      'Vert',
      'Jaune',
      'Rose',
      'Violet',
      'Orange',
      'Camel',
      'Kaki',
      'Bordeaux',
      'Doré',
      'Argenté',
      'Multicolore',
    ];
  }
}
