import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/settings_service.dart';
import 'product_import_draft.dart';
import 'product_import_parser.dart';
import 'product_import_csv_parser.dart';

enum _ProductImportMode { text, csv }

class ProductImportPage extends StatefulWidget {
  final ProductService productService;
  final SettingsService settingsService;

  const ProductImportPage({
    super.key,
    required this.productService,
    required this.settingsService,
  });

  @override
  State<ProductImportPage> createState() => _ProductImportPageState();
}

class _ProductImportPageState extends State<ProductImportPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _bulkPriceController = TextEditingController();

  List<ProductImportDraft> _drafts = [];
  final Set<int> _selectedIndexes = {};

  String _selectedBulkSize = 'Non renseignée';

  bool _isImporting = false;

  _ProductImportMode _importMode = _ProductImportMode.text;

  @override
  void dispose() {
    _textController.dispose();
    _bulkPriceController.dispose();
    super.dispose();
  }

  void _analyzeText() {
    final rawText = _textController.text.trim();

    if (rawText.isEmpty) {
      setState(() {
        _drafts = [];
        _selectedIndexes.clear();
      });
      return;
    }

    final settings = widget.settingsService.settings;

    final drafts = _importMode == _ProductImportMode.csv
        ? ProductImportCsvParser(
            productTypes: settings.productTypes,
            brands: settings.brands,
            colors: settings.colors,
            locations: settings.locations,
          ).parse(rawText)
        : ProductImportParser(
            productTypes: settings.productTypes,
            brands: settings.brands,
            colors: settings.colors,
            locations: settings.locations,
          ).parse(rawText);

    setState(() {
      _drafts = drafts;

      _selectedIndexes
        ..clear()
        ..addAll(List<int>.generate(drafts.length, (index) => index));
    });
  }

  void _clearImport() {
    setState(() {
      _textController.clear();
      _drafts.clear();
      _selectedIndexes.clear();
    });
  }

  void _toggleSelection(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndexes.add(index);
      } else {
        _selectedIndexes.remove(index);
      }
    });
  }

  void _toggleSelectAll(bool selected) {
    setState(() {
      if (selected) {
        _selectedIndexes
          ..clear()
          ..addAll(List.generate(_drafts.length, (index) => index));
      } else {
        _selectedIndexes.clear();
      }
    });
  }

  void _applyBulkSize() {
    if (_selectedIndexes.isEmpty) return;

    setState(() {
      _drafts = _drafts.asMap().entries.map((entry) {
        final index = entry.key;
        final draft = entry.value;

        if (!_selectedIndexes.contains(index)) {
          return draft;
        }

        return draft.copyWith(size: _selectedBulkSize);
      }).toList();
    });
  }

  void _applyBulkPrice() {
    if (_selectedIndexes.isEmpty) return;

    final priceText = _bulkPriceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prix invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _drafts = _drafts.asMap().entries.map((entry) {
        final index = entry.key;
        final draft = entry.value;

        if (!_selectedIndexes.contains(index)) {
          return draft;
        }

        return draft.copyWith(price: price);
      }).toList();
    });
  }

  int get _reviewCount {
    return _drafts.where((draft) => draft.needsReview).length;
  }

  int get _totalStock {
    return _drafts.fold<int>(0, (total, draft) => total + draft.stock);
  }

  String _normalizeForDuplicate(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
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
        .replaceAll('ç', 'c');
  }

  String _draftDuplicateKey(ProductImportDraft draft) {
    final brand = draft.brand == 'Sans marque' ? '' : draft.brand;

    return [
      _normalizeForDuplicate(draft.name),
      _normalizeForDuplicate(brand),
      _colorCodeFromText(draft.color).toString(),
      _sizeCodeFromText(draft.size).toString(),
    ].join('|');
  }

  String _productDuplicateKey(ProductModel product) {
    return [
      _normalizeForDuplicate(product.name),
      _normalizeForDuplicate(product.brand ?? ''),
      (product.colorCode ?? 0).toString(),
      (product.sizeCode ?? 0).toString(),
    ].join('|');
  }

  Set<String> get _existingProductKeys {
    return widget.productService.products.map(_productDuplicateKey).toSet();
  }

  List<int> get _draftIndexesToImport {
    if (_selectedIndexes.isEmpty) {
      return List<int>.generate(_drafts.length, (index) => index);
    }

    final sortedIndexes = _selectedIndexes.toList()..sort();

    return sortedIndexes
        .where((index) => index >= 0 && index < _drafts.length)
        .toList();
  }

  List<ProductImportDraft> get _draftsToImport {
    return _draftIndexesToImport.map((index) => _drafts[index]).toList();
  }

  Set<int> get _duplicateImportIndexes {
    final existingKeys = _existingProductKeys;
    final seenKeys = <String>{};
    final duplicateIndexes = <int>{};

    for (final index in _draftIndexesToImport) {
      final draft = _drafts[index];
      final key = _draftDuplicateKey(draft);

      if (existingKeys.contains(key) || seenKeys.contains(key)) {
        duplicateIndexes.add(index);
        continue;
      }

      seenKeys.add(key);
    }

    return duplicateIndexes;
  }

  List<ProductImportDraft> get _draftsToImportWithoutDuplicates {
    final duplicateIndexes = _duplicateImportIndexes;

    return _draftIndexesToImport
        .where((index) => !duplicateIndexes.contains(index))
        .map((index) => _drafts[index])
        .toList();
  }

  int get _importCount {
    return _draftsToImport.length;
  }

  int get _realImportCount {
    return _draftsToImportWithoutDuplicates.length;
  }

  int get _duplicateImportCount {
    return _duplicateImportIndexes.length;
  }

  int get _importStock {
    return _draftsToImportWithoutDuplicates.fold<int>(
      0,
      (total, draft) => total + draft.stock,
    );
  }

  int get _importReviewCount {
    return _draftsToImportWithoutDuplicates
        .where((draft) => draft.needsReview)
        .length;
  }

  int? _colorCodeFromText(String color) {
    final normalized = color.toLowerCase().trim();

    if (normalized.contains('noir')) return 1;
    if (normalized.contains('blanc')) return 2;
    if (normalized.contains('bleu')) return 3;
    if (normalized.contains('rouge')) return 4;
    if (normalized.contains('gris')) return 5;

    return null;
  }

  int? _sizeCodeFromText(String size) {
    final normalized = size.toUpperCase().trim();

    switch (normalized) {
      case 'XS':
        return 1;
      case 'S':
        return 2;
      case 'M':
        return 3;
      case 'L':
        return 4;
      case 'XL':
        return 5;
      default:
        return null;
    }
  }

  ProductModel _draftToProduct(ProductImportDraft draft) {
    return ProductModel(
      name: draft.name,
      brand: draft.brand == 'Sans marque' ? null : draft.brand,
      price: draft.price,
      stock: draft.stock,
      barcode: null,
      categoryCode: 10,
      colorCode: _colorCodeFromText(draft.color),
      sizeCode: _sizeCodeFromText(draft.size),
    );
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choisir un fichier CSV',
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    String content;

    if (file.bytes != null) {
      content = _decodeCsvBytes(file.bytes!);
    } else if (file.path != null) {
      final bytes = await File(file.path!).readAsBytes();
      content = _decodeCsvBytes(bytes);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lire le fichier sélectionné.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _importMode = _ProductImportMode.csv;
      _textController.text = content;
      _drafts = [];
      _selectedIndexes.clear();
    });

    _analyzeText();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fichier chargé et analysé : ${file.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _decodeCsvBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  Future<void> _importDrafts() async {
    if (_drafts.isEmpty || _isImporting) return;

    final draftsToImport = _draftsToImportWithoutDuplicates;
    final duplicateCount = _duplicateImportCount;
    final isPartialImport = _selectedIndexes.isNotEmpty;

    if (draftsToImport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun produit à importer : tout est déjà présent ou en doublon.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isPartialImport
                ? 'Importer la sélection'
                : 'Importer tous les produits',
          ),
          content: Text(
            'Produits analysés : $_importCount\n'
            'Produits à importer : $_realImportCount\n'
            'Doublons ignorés : $duplicateCount\n'
            'Stock total importé : $_importStock\n'
            'Lignes à vérifier : $_importReviewCount\n\n'
            '${duplicateCount > 0 ? 'Les doublons seront ignorés automatiquement.' : 'Aucun doublon détecté.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.upload_file),
              label: Text(
                duplicateCount > 0 ? 'Importer sans doublons' : 'Importer',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isImporting = true;
    });

    try {
      for (final draft in draftsToImport) {
        final product = _draftToProduct(draft);
        await widget.productService.addProduct(product);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${draftsToImport.length} produit(s) importé(s)'
            '${duplicateCount > 0 ? ' — $duplicateCount doublon(s) ignoré(s)' : ''}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur pendant l’import : $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settingsService.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Import rapide')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 420, child: _buildInputPanel()),
            const SizedBox(width: 16),
            Expanded(child: _buildPreviewPanel(settings.sizes)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Liste brute', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),

        _buildImportModeSelector(),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _textController,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _importMode == _ProductImportMode.csv
                  ? 'Colle ici ton CSV...'
                  : 'Colle ici ta liste de produits...',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _analyzeText,
                icon: const Icon(Icons.analytics),
                label: const Text('Analyser'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _clearImport,
              icon: const Icon(Icons.clear),
              label: const Text('Vider'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(List<String> availableSizes) {
    if (_drafts.isEmpty) {
      return const Center(child: Text('Aucun produit analysé pour le moment.'));
    }

    final allSelected = _selectedIndexes.length == _drafts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(),
        const SizedBox(height: 12),
        _buildBulkActions(availableSizes),
        const SizedBox(height: 12),
        _buildImportActions(),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allSelected,
                        onChanged: (value) {
                          _toggleSelectAll(value ?? false);
                        },
                      ),
                    ),
                    const DataColumn(label: Text('Nom')),
                    const DataColumn(label: Text('Type')),
                    const DataColumn(label: Text('Sous-catégorie')),
                    const DataColumn(label: Text('Marque')),
                    const DataColumn(label: Text('Couleur')),
                    const DataColumn(label: Text('Taille')),
                    const DataColumn(label: Text('Stock')),
                    const DataColumn(label: Text('Prix')),
                    const DataColumn(label: Text('Emplacement')),
                  ],
                  rows: _drafts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final draft = entry.value;
                    final selected = _selectedIndexes.contains(index);

                    return DataRow(
                      selected: selected,
                      color: WidgetStateProperty.resolveWith((states) {
                        if (draft.needsReview) {
                          return Colors.orange.withValues(alpha: 0.12);
                        }

                        return null;
                      }),
                      cells: [
                        DataCell(
                          Checkbox(
                            value: selected,
                            onChanged: (value) {
                              _toggleSelection(index, value ?? false);
                            },
                          ),
                        ),
                        DataCell(Text(draft.name)),
                        DataCell(Text(draft.type)),
                        DataCell(Text(draft.subCategory)),
                        DataCell(Text(draft.brand)),
                        DataCell(Text(draft.color)),
                        DataCell(Text(draft.size)),
                        DataCell(Text(draft.stock.toString())),
                        DataCell(Text('${draft.price.toStringAsFixed(2)} €')),
                        DataCell(Text(draft.location)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(label: 'Produits détectés', value: _drafts.length.toString()),
        _statCard(label: 'Stock total', value: _totalStock.toString()),
        _statCard(label: 'À vérifier', value: _reviewCount.toString()),
        _statCard(
          label: 'Sélectionnés',
          value: _selectedIndexes.length.toString(),
        ),
      ],
    );
  }

  Widget _statCard({required String label, required String value}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActions(List<String> availableSizes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Actions groupées',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: availableSizes.contains(_selectedBulkSize)
                    ? _selectedBulkSize
                    : availableSizes.firstOrNull,
                decoration: const InputDecoration(
                  labelText: 'Taille',
                  border: OutlineInputBorder(),
                ),
                items: availableSizes.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedBulkSize = value;
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedIndexes.isEmpty ? null : _applyBulkSize,
              icon: const Icon(Icons.straighten),
              label: const Text('Appliquer taille'),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _bulkPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Prix',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectedIndexes.isEmpty ? null : _applyBulkPrice,
              icon: const Icon(Icons.euro),
              label: const Text('Appliquer prix'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_ProductImportMode>(
          segments: const [
            ButtonSegment(
              value: _ProductImportMode.text,
              icon: Icon(Icons.notes),
              label: Text('Texte brut'),
            ),
            ButtonSegment(
              value: _ProductImportMode.csv,
              icon: Icon(Icons.table_chart),
              label: Text('CSV'),
            ),
          ],
          selected: {_importMode},
          onSelectionChanged: (selection) {
            setState(() {
              _importMode = selection.first;
              _drafts = [];
              _selectedIndexes.clear();
            });
          },
        ),
        if (_importMode == _ProductImportMode.csv) ...[
          const SizedBox(height: 8),
          Text(
            'Colonnes acceptées : type, brand, color, size, stock, price, pattern, location, description.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickCsvFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Choisir CSV'),
              ),
              OutlinedButton.icon(
                onPressed: _insertCsvTemplate,
                icon: const Icon(Icons.content_paste),
                label: const Text('Modèle CSV'),
              ),
              OutlinedButton.icon(
                onPressed: _exportCsvTemplate,
                icon: const Icon(Icons.save_alt),
                label: const Text('Exporter modèle'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImportActions() {
    final isPartialImport = _selectedIndexes.isNotEmpty;
    final duplicateCount = _duplicateImportCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isPartialImport
                    ? 'Import prévu : $_realImportCount produit(s) sélectionné(s), $_importStock article(s) en stock, $duplicateCount doublon(s) ignoré(s).'
                    : 'Import prévu : $_realImportCount produit(s), $_importStock article(s) en stock, $duplicateCount doublon(s) ignoré(s).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed:
                  _drafts.isEmpty || _isImporting || _realImportCount == 0
                  ? null
                  : _importDrafts,
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory),
              label: Text(
                _isImporting
                    ? 'Import...'
                    : isPartialImport
                    ? 'Importer la sélection'
                    : 'Importer toute la liste',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _csvTemplate {
    return [
      'type;brand;color;size;stock;price;pattern;location;description',
      'Pull;Women Only;Marron;;3;4,00;;Étagère 1;',
      'Pantalon;;Noir;M;7;4,00;cargo;Case 1;',
      'T-shirt;Nike;Blanc;L;2;2,00;logo;Rond 2;',
      'Robe;Zara;Rouge;S;1;5,00;fleurie;Portant 1;',
    ].join('\n');
  }

  void _insertCsvTemplate() {
    setState(() {
      _textController.text = _csvTemplate;
      _drafts = [];
      _selectedIndexes.clear();
    });
  }

  Future<void> _exportCsvTemplate() async {
    final csvContent = '\uFEFF$_csvTemplate\n';
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    final selectedPath = await FilePicker.saveFile(
      dialogTitle: 'Exporter le modèle CSV',
      fileName: 'modele_import_produits.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (selectedPath == null) {
      return;
    }

    final outputPath = selectedPath.toLowerCase().endsWith('.csv')
        ? selectedPath
        : '$selectedPath.csv';

    try {
      await File(outputPath).writeAsBytes(bytes, flush: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Modèle CSV exporté : $outputPath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur pendant l’export du modèle CSV : $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
