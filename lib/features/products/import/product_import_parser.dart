import 'product_import_draft.dart';

class ProductImportParser {
  final List<String> productTypes;
  final List<String> brands;
  final List<String> colors;
  final List<String> locations;
  final double defaultPrice;

  ProductImportParser({
    required this.productTypes,
    required this.brands,
    required this.colors,
    required this.locations,
    this.defaultPrice = 0,
  });

  static const String unknownValue = 'Non renseignée';

  List<ProductImportDraft> parse(String rawText) {
    final drafts = <ProductImportDraft>[];

    String currentLocation = unknownValue;
    String? inheritedType;

    for (final rawLine in rawText.split('\n')) {
      final cleanedLine = _cleanDiscordLine(rawLine);

      if (cleanedLine.isEmpty) continue;
      if (_isDiscordMetadataLine(cleanedLine)) continue;

      final locationResult = _extractLocationFromLine(cleanedLine);

      if (locationResult != null) {
        currentLocation = locationResult.location;

        if (locationResult.content.trim().isEmpty) {
          inheritedType = null;
          continue;
        }

        final parsedDrafts = _parseContentLine(
          rawLine: rawLine,
          content: locationResult.content,
          location: currentLocation,
          inheritedType: inheritedType,
        );

        drafts.addAll(parsedDrafts);

        if (parsedDrafts.isNotEmpty) {
          inheritedType = parsedDrafts.last.type;
        }

        continue;
      }

      final typeHeaderResult = _extractTypeHeader(cleanedLine);

      if (typeHeaderResult != null) {
        inheritedType = typeHeaderResult.type;

        final parsedDrafts = _parseContentLine(
          rawLine: rawLine,
          content: typeHeaderResult.content,
          location: currentLocation,
          inheritedType: inheritedType,
        );

        drafts.addAll(parsedDrafts);
        continue;
      }

      final parsedDrafts = _parseContentLine(
        rawLine: rawLine,
        content: cleanedLine,
        location: currentLocation,
        inheritedType: inheritedType,
      );

      drafts.addAll(parsedDrafts);

      if (parsedDrafts.isNotEmpty) {
        final lastType = parsedDrafts.last.type;

        if (lastType != 'Article') {
          inheritedType = lastType;
        }
      }
    }

    return _mergeSimilarDrafts(drafts);
  }

  List<ProductImportDraft> _parseContentLine({
    required String rawLine,
    required String content,
    required String location,
    String? inheritedType,
  }) {
    final segments = _splitItems(content);
    final drafts = <ProductImportDraft>[];

    String? segmentInheritedType = inheritedType;

    for (final segment in segments) {
      final draft = _parseItem(
        rawLine: rawLine,
        segment: segment,
        location: location,
        inheritedType: segmentInheritedType,
      );

      if (draft == null) continue;

      drafts.add(draft);

      if (draft.type != 'Article') {
        segmentInheritedType = draft.type;
      }
    }

    return drafts;
  }

  ProductImportDraft? _parseItem({
    required String rawLine,
    required String segment,
    required String location,
    String? inheritedType,
  }) {
    final quantityResult = _extractQuantity(segment);
    var workingText = _normalizeSpaces(quantityResult.text);

    if (workingText.isEmpty) return null;
    if (_isDiscordMetadataLine(workingText)) return null;
    if (_isOnlyNoise(workingText)) return null;

    final typeMatch = _findProductType(workingText);
    var type = typeMatch?.value;

    if (typeMatch != null) {
      workingText = _removeTextPart(workingText, typeMatch.matchedText);
    }

    type ??= inheritedType;

    final brandMatch = _findBrand(workingText);

    final brand = brandMatch?.value ?? 'Sans marque';

    if (brandMatch != null) {
      workingText = _removeTextPart(workingText, brandMatch.matchedText);
    }

    final colorMatch = _findColor(workingText);

    final color = colorMatch?.value ?? unknownValue;

    if (colorMatch != null) {
      workingText = _removeTextPart(workingText, colorMatch.matchedText);
    }

    final sizeMatch = _findSize(workingText);

    final size = sizeMatch?.value ?? unknownValue;

    if (sizeMatch != null) {
      workingText = _removeTextPart(workingText, sizeMatch.matchedText);
    }

    workingText = _cleanupRemainingText(workingText);

    if (type == null || type.trim().isEmpty) {
      if (_isOnlyColorOrQuantity(segment)) {
        return null;
      }

      final hasUsefulSignal =
          brand != 'Sans marque' ||
          color != unknownValue ||
          workingText.trim().isNotEmpty;

      if (!hasUsefulSignal) {
        return null;
      }

      type = 'Article';
    }

    if (type != 'Article' && _isOnlyColorOrQuantity(segment)) {
      return null;
    }

    final name = _buildProductName(type: type, remainingText: workingText);

    final category = _categoryForType(type);
    final subCategory = _subCategoryForType(type);
    final price = defaultPrice > 0 ? defaultPrice : _defaultPriceForType(type);

    return ProductImportDraft(
      rawLine: rawLine.trim(),
      name: name,
      type: type,
      category: category,
      subCategory: subCategory,
      brand: brand,
      color: color,
      size: size,
      location: location,
      description: _buildDescription(
        type: type,
        brand: brand,
        color: color,
        size: size,
        location: location,
      ),
      stock: quantityResult.quantity,
      price: price,
    );
  }

  String _cleanDiscordLine(String line) {
    var value = line.trim();

    value = value.replaceAll(RegExp(r'<@!?\d+>'), '');
    value = value.replaceAll(RegExp(r'^\s*[•\-*]\s*'), '');
    value = value.replaceAll(RegExp(r'^\s*\d+[\).]\s*'), '');

    value = value.replaceAll(
      RegExp(
        r'^.+?\s+[—-]\s+(aujourd’hui|aujourd hui|hier|today|yesterday|\d{1,2}/\d{1,2}/\d{2,4})\s+(à\s+)?\d{1,2}:\d{2}\s*',
        caseSensitive: false,
      ),
      '',
    );

    value = value.replaceAll(
      RegExp(
        r'^(aujourd’hui|aujourd hui|hier|today|yesterday)\s+(à\s+)?\d{1,2}:\d{2}\s*$',
        caseSensitive: false,
      ),
      '',
    );

    value = value.replaceAll(RegExp(r'^\d{1,2}:\d{2}\s*$'), '');

    return _normalizeSpaces(value);
  }

  bool _isDiscordMetadataLine(String line) {
    final value = line.trim();

    if (value.isEmpty) return true;

    final normalized = _normalize(value);

    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) return true;

    if (RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}$').hasMatch(value)) {
      return true;
    }

    if (normalized == 'aujourdhui' ||
        normalized == 'aujourd hui' ||
        normalized == 'hier' ||
        normalized == 'today' ||
        normalized == 'yesterday') {
      return true;
    }

    final hasProductSignal =
        _findProductType(value) != null ||
        _findBrand(value) != null ||
        _findColor(value) != null ||
        _extractQuantity(value).quantity > 1 ||
        _looksLikeLocation(value);

    if (!hasProductSignal && value.length <= 32 && !value.contains(' ')) {
      return true;
    }

    return false;
  }

  bool _isOnlyNoise(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) return true;
    if (RegExp(r'^[\d\sx×*().:-]+$', caseSensitive: false).hasMatch(cleaned)) {
      return true;
    }

    return false;
  }

  bool _isOnlyColorOrQuantity(String value) {
    final quantityResult = _extractQuantity(value);
    final withoutQuantity = quantityResult.text.trim();

    if (withoutQuantity.isEmpty) return true;

    final colorMatch = _findColor(withoutQuantity);

    if (colorMatch == null) return false;

    final rest = _cleanupRemainingText(
      _removeTextPart(withoutQuantity, colorMatch.matchedText),
    );

    return rest.isEmpty;
  }

  _LocationLineResult? _extractLocationFromLine(String line) {
    final colonIndex = line.indexOf(':');

    if (colonIndex != -1) {
      final left = line.substring(0, colonIndex).trim();
      final right = line.substring(colonIndex + 1).trim();

      if (_looksLikeLocation(left)) {
        return _LocationLineResult(
          location: _canonicalLocation(left),
          content: right,
        );
      }
    }

    if (_looksLikeLocation(line) && _findProductType(line) == null) {
      return _LocationLineResult(
        location: _canonicalLocation(line),
        content: '',
      );
    }

    return null;
  }

  _TypeHeaderResult? _extractTypeHeader(String line) {
    final colonIndex = line.indexOf(':');

    if (colonIndex == -1) return null;

    final left = line.substring(0, colonIndex).trim();
    final right = line.substring(colonIndex + 1).trim();

    final typeMatch = _findProductType(left);

    if (typeMatch == null) return null;

    final remaining = _cleanupRemainingText(
      _removeTextPart(left, typeMatch.matchedText),
    );

    if (remaining.isNotEmpty) return null;

    return _TypeHeaderResult(type: typeMatch.value, content: right);
  }

  bool _looksLikeLocation(String value) {
    final normalized = _normalize(value);

    final locationKeywords = [
      'case',
      'etagere',
      'rond',
      'carre',
      'portant',
      'bac',
      'panier',
      'rayon',
      'carton',
      'sac',
      'table',
    ];

    if (locations.any((location) => _normalize(location) == normalized)) {
      return true;
    }

    return locationKeywords.any(
      (keyword) => normalized == keyword || normalized.startsWith('$keyword '),
    );
  }

  String _canonicalLocation(String value) {
    final normalized = _normalize(value);

    for (final location in locations) {
      if (_normalize(location) == normalized) {
        return location.trim();
      }
    }

    return _capitalizeWords(value.trim());
  }

  List<String> _splitItems(String content) {
    return content
        .split(RegExp(r'[,;]'))
        .map(_normalizeSpaces)
        .where((item) => item.isNotEmpty)
        .toList();
  }

  _QuantityResult _extractQuantity(String input) {
    var text = _normalizeSpaces(input);
    var quantity = 1;

    final suffixPatterns = [
      RegExp(r'(?:^|\s)[x×*]\s*(\d+)\s*$', caseSensitive: false),
      RegExp(r'\((\d+)\)\s*$', caseSensitive: false),
    ];

    for (final pattern in suffixPatterns) {
      final match = pattern.firstMatch(text);

      if (match != null) {
        quantity = int.tryParse(match.group(1) ?? '') ?? 1;
        text = text.replaceRange(match.start, match.end, '').trim();

        return _QuantityResult(
          text: _normalizeSpaces(text),
          quantity: quantity < 1 ? 1 : quantity,
        );
      }
    }

    final prefixWithX = RegExp(
      r'^\s*(\d+)\s*[x×*]\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);

    if (prefixWithX != null) {
      quantity = int.tryParse(prefixWithX.group(1) ?? '') ?? 1;
      text = prefixWithX.group(2) ?? '';

      return _QuantityResult(
        text: _normalizeSpaces(text),
        quantity: quantity < 1 ? 1 : quantity,
      );
    }

    final prefixNumber = RegExp(r'^\s*(\d+)\s+(.+)$').firstMatch(text);

    if (prefixNumber != null) {
      quantity = int.tryParse(prefixNumber.group(1) ?? '') ?? 1;
      text = prefixNumber.group(2) ?? '';

      return _QuantityResult(
        text: _normalizeSpaces(text),
        quantity: quantity < 1 ? 1 : quantity,
      );
    }

    return _QuantityResult(text: text, quantity: quantity);
  }

  _MatchedValue? _findProductType(String text) {
    final candidates = <String, String>{};

    for (final type in _defaultProductTypes) {
      candidates[type] = type;
    }

    for (final type in productTypes) {
      if (type.trim().isNotEmpty) {
        candidates[type.trim()] = _capitalizeWords(type.trim());
      }
    }

    final aliases = <String, String>{
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
    };

    candidates.addAll(aliases);

    return _findCandidate(text, candidates);
  }

  _MatchedValue? _findBrand(String text) {
    final candidates = <String, String>{};

    for (final brand in brands) {
      if (brand.trim().isNotEmpty) {
        candidates[brand.trim()] = _normalizeBrandName(brand.trim());
      }
    }

    final aliases = <String, String>{
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
    };

    candidates.addAll(aliases);

    return _findCandidate(text, candidates);
  }

  _MatchedValue? _findColor(String text) {
    final candidates = <String, String>{};

    for (final color in _defaultColors) {
      candidates[color] = color;
    }

    for (final color in colors) {
      if (color.trim().isNotEmpty) {
        candidates[color.trim()] = _capitalizeWords(color.trim());
      }
    }

    final aliases = <String, String>{
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
    };

    candidates.addAll(aliases);

    return _findCandidate(text, candidates);
  }

  _MatchedValue? _findSize(String text) {
    final sizes = [
      'XXS',
      'XS',
      'S',
      'M',
      'L',
      'XL',
      'XXL',
      'XXXL',
      '34',
      '36',
      '38',
      '40',
      '42',
      '44',
      '46',
      '48',
      '50',
      'TU',
      'Taille unique',
    ];

    for (final size in sizes) {
      final regex = RegExp(
        r'(^|[^a-zA-Z0-9])' + RegExp.escape(size) + r'($|[^a-zA-Z0-9])',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match != null) {
        final matchedText = text.substring(match.start, match.end).trim();

        return _MatchedValue(
          value: size.toUpperCase() == 'TAILLE UNIQUE' ? 'TU' : size,
          matchedText: matchedText,
        );
      }
    }

    return null;
  }

  _MatchedValue? _findCandidate(String text, Map<String, String> candidates) {
    final sortedEntries = candidates.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedEntries) {
      final candidate = entry.key.trim();

      if (candidate.isEmpty) continue;

      final regex = RegExp(
        r'(^|[^a-zA-Z0-9])' + RegExp.escape(candidate) + r'($|[^a-zA-Z0-9])',
        caseSensitive: false,
      );

      final match = regex.firstMatch(text);

      if (match == null) continue;

      final matchedText = text.substring(match.start, match.end).trim();

      return _MatchedValue(value: entry.value, matchedText: matchedText);
    }

    final normalizedText = _normalize(text);

    for (final entry in sortedEntries) {
      final candidate = entry.key.trim();

      if (candidate.isEmpty) continue;

      final normalizedCandidate = _normalize(candidate);

      if (normalizedText == normalizedCandidate ||
          normalizedText.contains(' $normalizedCandidate ') ||
          normalizedText.startsWith('$normalizedCandidate ') ||
          normalizedText.endsWith(' $normalizedCandidate')) {
        return _MatchedValue(value: entry.value, matchedText: candidate);
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

  String _buildProductName({
    required String type,
    required String remainingText,
  }) {
    final cleanType = type.trim().isEmpty ? 'Article' : type.trim();
    final motif = _cleanupRemainingText(remainingText);

    if (motif.isEmpty) {
      return cleanType;
    }

    if (_normalize(motif) == _normalize(cleanType)) {
      return cleanType;
    }

    return '$cleanType ${motif.toLowerCase()}';
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

class _QuantityResult {
  final String text;
  final int quantity;

  const _QuantityResult({required this.text, required this.quantity});
}

class _MatchedValue {
  final String value;
  final String matchedText;

  const _MatchedValue({required this.value, required this.matchedText});
}

class _LocationLineResult {
  final String location;
  final String content;

  const _LocationLineResult({required this.location, required this.content});
}

class _TypeHeaderResult {
  final String type;
  final String content;

  const _TypeHeaderResult({required this.type, required this.content});
}
