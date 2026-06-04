import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../data/models/product_model.dart';
import '../../data/services/barcode_service.dart';
import '../../data/services/product_service.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  final _productService = ProductService();
  final _barcodeService = BarcodeService();
  final _seedController = TextEditingController();

  int? _selectedProductIndex;
  String? _generatedBarcode;
  String? _error;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _generateForSelectedProduct() {
    if(_selectedProductIndex == null) {
      setState(() {
        _error = 'Veuillez sélectionner un produit';
        _generatedBarcode = null;
      });

      return;
    }

    final seed = _seedController.text.trim();

    try {
      final ean13 = _barcodeService.generateEan13FromSeed(seed);

      _productService.updateProductBarcode(_selectedProductIndex!, ean13);

      setState(() {
        _generatedBarcode = ean13;
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code-barres généré et attribué au produit'),
        ),
      );
    } catch (e) {
      setState(() {
        _generatedBarcode = null;
        _error = e.toString();
      });
    }
  }

  void _selectProduct(int index, ProductModel product) {
    setState(() {
      _selectedProductIndex = index;
      _generatedBarcode = product.barcode;
      _error = null;

      if(product.barcode != null && product.barcode!.length >= 12) {
        _seedController.text = product.barcode!.substring(0, 12);
      } else {
        _seedController.text = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _productService.products;
    final selectedProduct = _selectedProductIndex != null
      ? products[_selectedProductIndex!]
      : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Codes-barres', style: Theme.of(context).textTheme.titleLarge),

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attribuer un EAN-13 à un produit',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _selectedProductIndex, 
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un produit',
                  ),

                  items: products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;

                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(product.name),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if(value == null) return;
                    _selectProduct(value, products[value]);
                  },
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _seedController,
                  decoration: const InputDecoration(
                    labelText: 'Base de 12 chiffres',
                    hintText: 'Ex : 123456789012',
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: products.isEmpty ? null : _generateForSelectedProduct,
                  icon: const Icon(Icons.qr_code),
                  label: Text('Générer et attribuer'),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                if(selectedProduct != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Produit sélectionné : ${selectedProduct.name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],

                if (_generatedBarcode != null) ...[
                  const SizedBox(height: 20),
                  BarcodeWidget(
                    barcode: Barcode.ean13(),
                    data: _generatedBarcode!,
                    width: 320,
                    height: 100,
                    drawText: true,
                  ),

                  const SizedBox(height: 8),
                  Text('Code : $_generatedBarcode'),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: products.isEmpty
                  ? const Center(child: Text('Aucun produit disponible'))
                  : ListView.separated(
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final product = products[index];

                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            product.barcode == null
                                ? 'Pas de code-barres'
                                : 'Code-barres : ${product.barcode}',
                          ),

                          trailing: TextButton(
                            onPressed: () => _selectProduct(index, product),
                            child: const Text('Sélectionner'),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
