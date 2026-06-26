import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../data/models/label_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/label_pdf_service.dart';
import '../../data/services/product_service.dart';
import '../../data/services/settings_service.dart';

import './import/product_import_page.dart';

class ProductsPage extends StatefulWidget {
  final ProductService productService;
  final SettingsService settingsService;

  const ProductsPage({
    super.key,
    required this.productService,
    required this.settingsService,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _labelQuantityController = TextEditingController(text: '1');

  late final ProductService _productService = widget.productService;
  final LabelPdfService _labelPdfService = LabelPdfService();

  int? _editingProductId;

  int _selectedCategoryCode = 10;
  int? _selectedColorCode;
  int? _selectedSizeCode;

  final Set<int> _selectedRows = {};

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _labelQuantityController.dispose();
    super.dispose();
  }

  void _startEditing(ProductModel product) {
    setState(() {
      _editingProductId = product.id;
      _selectedCategoryCode = product.categoryCode;
      _selectedColorCode = product.colorCode;
      _selectedSizeCode = product.sizeCode;
    });

    _nameController.text = product.name;
    _brandController.text = product.brand ?? '';
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _barcodeController.text = product.barcode ?? '';
  }

  void _resetForm() {
    _editingProductId = null;
    _nameController.clear();
    _brandController.clear();
    _priceController.clear();
    _stockController.clear();
    _barcodeController.clear();
    _selectedCategoryCode = 10;
    _selectedColorCode = null;
    _selectedSizeCode = null;
  }

  void _cancelEditing() {
    setState(_resetForm);
  }

  Future<void> _deleteProduct(ProductModel product) async {
    if (product.id == null) return;

    await _productService.deleteProduct(product.id!);

    if (!mounted) return;

    setState(() {
      _selectedRows.remove(product.id);

      if (_editingProductId == product.id) {
        _resetForm();
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final brand = _brandController.text.trim();

    final baseProduct = ProductModel(
      id: _editingProductId,
      name: _nameController.text.trim(),
      brand: brand.isEmpty ? null : brand,
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stockController.text.trim()),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      categoryCode: _selectedCategoryCode,
      colorCode: _selectedColorCode,
      sizeCode: _selectedSizeCode,
    );

    final isEditing = _editingProductId != null;
    final String message = isEditing
        ? 'Produit mis à jour'
        : 'Produit ajouté avec succès';

    if (isEditing) {
      await _productService.updateProduct(baseProduct);
    } else {
      await _productService.addProduct(baseProduct);
    }

    if (!mounted) return;

    setState(_resetForm);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryLabel(int code) {
    switch (code) {
      case 10:
        return 'Vêtement';
      default:
        return 'Autre';
    }
  }

  String _colorLabel(int? code) {
    switch (code) {
      case 1:
        return 'Noir';
      case 2:
        return 'Blanc';
      case 3:
        return 'Bleu';
      case 4:
        return 'Rouge';
      case 5:
        return 'Gris';
      default:
        return '-';
    }
  }

  String _sizeLabel(int? code) {
    switch (code) {
      case 1:
        return 'XS';
      case 2:
        return 'S';
      case 3:
        return 'M';
      case 4:
        return 'L';
      case 5:
        return 'XL';
      default:
        return '-';
    }
  }

  Future<void> _generateLabelsPdf() async {
    if (_selectedRows.isEmpty) return;

    final quantity = int.tryParse(_labelQuantityController.text.trim()) ?? 1;
    if (quantity <= 0) return;

    final items = _productService.products
        .where(
          (product) => product.id != null && _selectedRows.contains(product.id),
        )
        .map((product) => LabelItemModel(product: product, quantity: quantity))
        .toList();

    if (items.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 900,
            height: 700,
            child: PdfPreview(
              build: (format) => _labelPdfService.generateLabelsPdf(items),
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _productService,
      builder: (context, _) {
        final bool isEditing = _editingProductId != null;
        final products = _productService.products;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Modifier le produit'
                                        : 'Ajouter un produit',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) {
                                                return ProductImportPage(
                                                  settingsService:
                                                      widget.settingsService,
                                                );
                                              },
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text('Import rapide'),
                                      ),
                                      if (isEditing) ...[
                                        const SizedBox(width: 12),
                                        TextButton.icon(
                                          onPressed: _cancelEditing,
                                          icon: const Icon(Icons.close),
                                          label: const Text('Annuler'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nom du produit',
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Le nom est obligatoire';
                                        }
                                        if (value.trim().length < 2) {
                                          return 'Le nom est trop court';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _brandController,
                                      decoration: const InputDecoration(
                                        labelText: 'Marque (optionnel)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prix',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Le prix est obligatoire';
                                        }

                                        final parsed = double.tryParse(
                                          value.trim().replaceAll(',', '.'),
                                        );

                                        if (parsed == null) {
                                          return 'Prix invalide';
                                        }

                                        if (parsed < 0) {
                                          return 'Le prix doit être positif';
                                        }

                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _stockController,
                                      decoration: const InputDecoration(
                                        labelText: 'Stock',
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Le stock est obligatoire';
                                        }

                                        final parsed = int.tryParse(
                                          value.trim(),
                                        );

                                        if (parsed == null) {
                                          return 'Stock invalide';
                                        }

                                        if (parsed < 0) {
                                          return 'Le stock doit être positif';
                                        }

                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _barcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Code-barres (optionnel)',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      initialValue: _selectedCategoryCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Catégorie',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 10,
                                          child: Text('10 - Vêtements'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedCategoryCode = value,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int?>(
                                      initialValue: _selectedColorCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Couleur (optionnel)',
                                      ),
                                      items: const [
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('N/A'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 1,
                                          child: Text('01 - Noir'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 2,
                                          child: Text('02 - Blanc'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 3,
                                          child: Text('03 - Bleu'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 4,
                                          child: Text('04 - Rouge'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 5,
                                          child: Text('05 - Gris'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(
                                          () => _selectedColorCode = value,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<int?>(
                                      initialValue: _selectedSizeCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Taille (optionnel)',
                                      ),
                                      items: const [
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text('N/A'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 1,
                                          child: Text('01 - XS'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 2,
                                          child: Text('02 - S'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 3,
                                          child: Text('03 - M'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 4,
                                          child: Text('04 - L'),
                                        ),
                                        DropdownMenuItem<int?>(
                                          value: 5,
                                          child: Text('05 - XL'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(
                                          () => _selectedSizeCode = value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: _submitProduct,
                                  icon: Icon(
                                    isEditing ? Icons.save : Icons.add,
                                  ),
                                  label: Text(
                                    isEditing ? 'Enregistrer' : 'Ajouter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 220,
                              child: TextFormField(
                                controller: _labelQuantityController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Qté étiquettes / produit',
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _selectedRows.isEmpty
                                  ? null
                                  : _generateLabelsPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Générer les étiquettes PDF'),
                            ),
                            Text(
                              '${_selectedRows.length} produit(s) sélectionné(s)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 420,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _productService.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : products.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucun produit enregistré pour le moment',
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Scrollbar(
                                      thumbVisibility: true,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
                                            ),
                                            child: DataTable(
                                              showCheckboxColumn: true,
                                              columns: const [
                                                DataColumn(label: Text('Nom')),
                                                DataColumn(
                                                  label: Text('Marque'),
                                                ),
                                                DataColumn(label: Text('Prix')),
                                                DataColumn(
                                                  label: Text('Stock'),
                                                ),
                                                DataColumn(
                                                  label: Text('Catégorie'),
                                                ),
                                                DataColumn(
                                                  label: Text('Couleur'),
                                                ),
                                                DataColumn(
                                                  label: Text('Taille'),
                                                ),
                                                DataColumn(
                                                  label: Text('Code-barres'),
                                                ),
                                                DataColumn(
                                                  label: Text('Actions'),
                                                ),
                                              ],
                                              rows: products.map((product) {
                                                final productId = product.id;
                                                final isSelected =
                                                    productId != null &&
                                                    _selectedRows.contains(
                                                      productId,
                                                    );

                                                return DataRow(
                                                  selected: isSelected,
                                                  onSelectChanged:
                                                      productId == null
                                                      ? null
                                                      : (selected) {
                                                          setState(() {
                                                            if (selected ??
                                                                false) {
                                                              _selectedRows.add(
                                                                productId,
                                                              );
                                                            } else {
                                                              _selectedRows
                                                                  .remove(
                                                                    productId,
                                                                  );
                                                            }
                                                          });
                                                        },
                                                  color:
                                                      WidgetStateProperty.resolveWith<
                                                        Color?
                                                      >(
                                                        (states) =>
                                                            _editingProductId ==
                                                                product.id
                                                            ? Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                    alpha: 0.08,
                                                                  )
                                                            : null,
                                                      ),
                                                  cells: [
                                                    DataCell(
                                                      Text(product.name),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        product.brand ??
                                                            'Sans marque',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${product.price.toStringAsFixed(2)} €',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        product.stock
                                                            .toString(),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _categoryLabel(
                                                          product.categoryCode,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _colorLabel(
                                                          product.colorCode,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        _sizeLabel(
                                                          product.sizeCode,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        product.barcode ?? '-',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 20,
                                                            ),
                                                            tooltip: 'Modifier',
                                                            onPressed: () =>
                                                                _startEditing(
                                                                  product,
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              size: 20,
                                                              color: Colors.red,
                                                            ),
                                                            tooltip:
                                                                'Supprimer',
                                                            onPressed: () =>
                                                                _deleteProduct(
                                                                  product,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
