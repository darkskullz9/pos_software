import 'package:flutter/material.dart';

import '../../data/models/product_model.dart';
import '../../data/services/product_service.dart';

class ProductsPage extends StatefulWidget {
  final ProductService productService;

  const ProductsPage({
    super.key,
    required this.productService,
  });

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}
  
class _ProductsPageState extends State<ProductsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  late final ProductService _productService = widget.productService;

  int? _editingIndex;

  int _selectedCategoryCode = 10;
  int _selectedColorCode = 1;
  int _selectedSizeCode = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _startEditing(int index) {
    final product = _productService.products[index];

    setState(() {
      _editingIndex = index;
      _selectedCategoryCode = product.categoryCode;
      _selectedColorCode = product.colorCode;
      _selectedSizeCode = product.sizeCode;
    });

    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _barcodeController.text = product.barcode ?? '';
  }

  void _resetForm() {
    _editingIndex = null;
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _barcodeController.clear();
    _selectedCategoryCode = 10;
    _selectedColorCode = 1;
    _selectedSizeCode = 3;
  }

  void _cancelEditing() {
    setState(_resetForm);
  }

  void _deleteProduct(int index) {
    setState(() {
      _productService.deleteProduct(index);

      if(_editingIndex == index) {
        _resetForm();
      } else if(_editingIndex != null && _editingIndex! > index) {
        _editingIndex = _editingIndex! - 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produit supprimé')
      ),
    );
  }

  void _submitProduct() {
    if(!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stockController.text.trim()),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      categoryCode: _selectedCategoryCode,
      colorCode: _selectedColorCode,
      sizeCode: _selectedSizeCode,
    );

    final String message = _editingIndex != null ? 'Produit mis à jour' : 'Produit ajouté avec succès';

    setState(() {
      if(_editingIndex != null) {
        _productService.updateProduct(_editingIndex!, product);
        _resetForm();
      } else {
        _productService.addProduct(product);
        _resetForm();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message)
      ),
    );
  }

  String _categoryLabel(int code) {
    switch (code) {
      case 10:
        return 'Vêtement';
      default:
        return 'Autre';
    }
  }

  String _colorLabel(int code) {
    switch (code) {
      case 1:
        return 'Noir';
      case 2:
        return 'Blanc';
      case 3:
        return 'Bleu';
      case 4:
        return 'Rouge';
      default:
        return 'Inconnu';
    }
  }

  String _sizeLabel(int code) {
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _editingIndex != null;
    final products = _productService.products;
    
    return Column(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Modifier le produit' : 'Ajouter un produit', 
                        style: Theme.of(context).textTheme.titleLarge
                      ),

                      if(isEditing)
                        TextButton.icon(
                          onPressed: _cancelEditing,
                          icon: const Icon(Icons.close),
                          label: const Text('Annuler'),
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
                            if(value == null || value.trim().isEmpty) {
                              return 'Le nom est obligatoire';
                            }

                            if(value.trim().length < 2) {
                              return 'Le nom est trop court';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Prix',
                          ),

                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),

                          validator: (value) {
                            if(value == null || value.trim().isEmpty) {
                              return 'Le prix est obligatoire';
                            }

                            final parsed = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );

                            if(parsed == null) {
                              return 'Prix invalide';
                            }

                            if(parsed < 0) {
                              return 'Le prix doit être positif';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                          ),

                          keyboardType: TextInputType.number,

                          validator: (value) {
                            if(value == null || value.trim().isEmpty) {
                              return 'Le stock est obligatoire';
                            }

                            final parsed = int.tryParse(value.trim());

                            if(parsed == null) {
                              return 'Stock invalide';
                            }

                            if(parsed < 0) {
                              return 'Le stock doit être positif';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Code-barres (optionnel)',
                          ),
                        ),
                      ),
                    ],
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
                              setState(() => _selectedCategoryCode = value);
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedColorCode,
                          decoration: const InputDecoration(
                            labelText: 'Couleur',
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('01 - Noir')),
                            DropdownMenuItem(value: 2, child: Text('02 - Blanc')),
                            DropdownMenuItem(value: 3, child: Text('03 - Bleu')),
                            DropdownMenuItem(value: 4, child: Text('04 - Rouge')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedColorCode = value);
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedSizeCode,
                          decoration: const InputDecoration(
                            labelText: 'Taille',
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('01 - XS')),
                            DropdownMenuItem(value: 2, child: Text('02 - S')),
                            DropdownMenuItem(value: 3, child: Text('03 - M')),
                            DropdownMenuItem(value: 4, child: Text('04 - L')),
                            DropdownMenuItem(value: 5, child: Text('05 - XL')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSizeCode = value);
                            }
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
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: products.isEmpty 
                ? const Center(
                  child: Text('Aucun produit enregistré pour le moment')
                )

                : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Prix')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Catégorie')),
                      DataColumn(label: Text('Couleur')),
                      DataColumn(label: Text('Taille')),
                      DataColumn(label: Text('Code-barres')),
                      DataColumn(label: Text('Actions')),
                    ],

                    rows: products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>(
                          (states) => _editingIndex == index 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                            : null,
                        ),

                        cells: [
                          DataCell(Text(product.name)),
                          DataCell(Text('${product.price.toStringAsFixed(2)} €')),
                          DataCell(Text(product.stock.toString())),
                          DataCell(Text(_categoryLabel(product.categoryCode))),
                          DataCell(Text(_colorLabel(product.colorCode))),
                          DataCell(Text(_sizeLabel(product.sizeCode))),
                          DataCell(Text(product.barcode ?? '-')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined, 
                                    size: 20,
                                  ),
                                  
                                  tooltip: 'Modifier',
                                  onPressed: () => _startEditing(index),
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),

                                  tooltip: 'Supprimer',
                                  onPressed: () => _deleteProduct(index),
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
        ),
      ],
    );
  }
}