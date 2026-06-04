import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../data/services/product_service.dart';

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  final _productService = ProductService();

  String? _selectedBarcode;
  String? _selectedLabel;

  void _showBarcode(String name, String? barcode) {
    setState(() {
      _selectedLabel = name;
      _selectedBarcode = barcode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _productService.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Codes-barres', 
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _selectedBarcode == null 
              ? const Text('Sélectionnez un article pour afficher son code-barres')
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedLabel ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  const SizedBox(height: 16),
                  BarcodeWidget(
                    barcode: Barcode.ean13(),
                    data: _selectedBarcode!,
                    width: 320,
                    height: 100,
                    drawText: true,
                  ),

                  const SizedBox(height: 8),
                  Text('Code : $_selectedBarcode'),
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
                            'Code-barres : ${product.barcode ?? 'Non généré'}'
                          ),

                          trailing: TextButton(
                            onPressed: product.barcode == null 
                            ? null
                            : () => _showBarcode(product.name, product.barcode),
                            child: const Text('Afficher'),
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
