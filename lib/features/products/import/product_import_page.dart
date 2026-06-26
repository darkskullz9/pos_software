import 'package:flutter/material.dart';

import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import '../../../data/services/settings_service.dart';
import 'product_import_draft.dart';
import 'product_import_parser.dart';

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

  @override
  void dispose() {
    _textController.dispose();
    _bulkPriceController.dispose();
    super.dispose();
  }

  void _analyzeText() {
    final settings = widget.settingsService.settings;

    final parser = ProductImportParser(
      productTypes: settings.productTypes,
      brands: settings.brands,
      colors: settings.colors,
      locations: settings.locations,
    );

    final drafts = parser.parse(_textController.text);

    setState(() {
      _drafts = drafts;
      _selectedIndexes.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${drafts.length} produit(s) détecté(s)')),
    );
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

  List<ProductImportDraft> get _draftsToImport {
    if (_selectedIndexes.isEmpty) {
      return _drafts;
    }

    final sortedIndexes = _selectedIndexes.toList()..sort();

    return sortedIndexes
        .where((index) => index >= 0 && index < _drafts.length)
        .map((index) => _drafts[index])
        .toList();
  }

  int get _importCount {
    return _draftsToImport.length;
  }

  int get _importStock {
    return _draftsToImport.fold<int>(0, (total, draft) => total + draft.stock);
  }

  int get _importReviewCount {
    return _draftsToImport.where((draft) => draft.needsReview).length;
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

  Future<void> _importDrafts() async {
    if (_drafts.isEmpty || _isImporting) return;

    final draftsToImport = _draftsToImport;

    if (draftsToImport.isEmpty) return;

    final isPartialImport = _selectedIndexes.isNotEmpty;

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
            'Produits à importer : ${draftsToImport.length}\n'
            'Stock total : $_importStock\n'
            'Lignes à vérifier : $_importReviewCount\n\n'
            '${isPartialImport ? 'Seules les lignes sélectionnées seront importées.' : 'Aucune ligne sélectionnée : toute la liste sera importée.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.upload_file),
              label: const Text('Importer'),
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
          content: Text('${draftsToImport.length} produit(s) importé(s)'),
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
        Expanded(
          child: TextField(
            controller: _textController,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Colle ici ta liste de produits...',
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
                value: availableSizes.contains(_selectedBulkSize)
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

  Widget _buildImportActions() {
    final isPartialImport = _selectedIndexes.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isPartialImport
                    ? 'Import prévu : $_importCount produit(s) sélectionné(s), stock total $_importStock, $_importReviewCount ligne(s) à vérifier.'
                    : 'Aucune ligne sélectionnée : l’import ajoutera toute la liste ($_importCount produit(s), stock total $_importStock).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _drafts.isEmpty || _isImporting ? null : _importDrafts,
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
}
