import 'package:flutter/material.dart';

import '../../data/models/product_model.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}
  
class _ProductsPageState extends State<ProductsPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  final List<ProductModel> _products = [];

  int? _editingIndex;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _startEditing(int index) {
    final product = _products[index];
    setState(() {
      _editingIndex = index;
    });

    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _stockController.text = product.stock.toString();
    _barcodeController.text = product.barcode ?? '';
  }

  void _cancelEditing() {
    setState(() {
      _editingIndex = null;
    });

    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _barcodeController.clear();
  }

  void _deleteProduct(int index) {
    setState(() {
      _products.removeAt(index);

      if(_editingIndex == index) {
        _editingIndex = null;
        _nameController.clear();
        _priceController.clear();
        _stockController.clear();
        _barcodeController.clear();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produit supprimé')),
    );
  }

  void _submitProduct() {
    if(!_formKey.currentState!.validate()) return;

    final product = ProductModel(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stockController.text.trim()),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
    );

    setState(() {
      if(_editingIndex != null) {
        _products[_editingIndex!] = product;
        _editingIndex = null;
      } else {
        _products.add(product);
      }
    });

    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _barcodeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_editingIndex != null ? 'Produit mis à jour' : 'Produit ajouté avec succès')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _editingIndex != null;
    
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

                            if(parsed == null) return 'Prix invalide';
                            if(parsed < 0) return 'Le prix doit être positif';

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

                            if(parsed == null) return 'Stock invalide';
                            if(parsed < 0) return 'Le stock doit êtrepositif';

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
              child: _products.isEmpty 
              ? const Center(child: Text('Aucun produit enregistré pour le moment'))
              : SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nom')),
                    DataColumn(label: Text('Prix')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Code-barres')),
                    DataColumn(label: Text('Actions')),
                  ],

                  rows: _products.asMap().entries.map((entry) {
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
                        DataCell(Text(product.barcode ?? '-')),
                        DataCell(Row(
                          children: [
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