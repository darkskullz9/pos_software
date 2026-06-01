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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _addProduct() {
    if(!_formKey.currentState!.validate()) {
      return;
    }

    final product = ProductModel(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stockController.text.trim()),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
    );

    setState(() {
      _products.add(product);
    });

    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    _barcodeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produit ajouté avec succès'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Ajouter un produit', style: Theme.of(context).textTheme.titleLarge),

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

                          keyboardType: TextInputType.numberWithOptions(decimal: true),

                          validator: (value) {
                            if(value == null || value.trim().isEmpty) {
                              return 'Le prix est obligatoire';
                            }

                            final price = double.tryParse(value.trim().replaceAll(',', '.'));
                            if(price == null || price < 0) {
                              return 'Le prix doit être un nombre positif';
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

                            final stock = int.tryParse(value.trim());

                            if(stock == null || stock < 0) {
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

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
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
                  ],

                  rows: _products.map((product) {
                    return DataRow(
                      cells: [
                        DataCell(Text(product.name)),
                        DataCell(Text('${product.price.toStringAsFixed(2)} €')),
                        DataCell(Text(product.stock.toString())),
                        DataCell(Text(product.barcode ?? '-')),
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