import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

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

  String? _generatedBarcode;
  String? _error;

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _generateForSeed() {
    final seed = _seedController.text.trim();

    try {
      final ean13 = _barcodeService.generateEan13FromSeed(seed);
      setState(() {
        _generatedBarcode = ean13;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _generatedBarcode = null;
        _error = e.toString();
      });
    }
  }

  void _useProductBarcode(String? barcode) {
    setState(() {
      _generatedBarcode = barcode;
      _error = null;
      _seedController.text = barcode ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = _productService.products;

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
                  'Générer un EAN-13',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: _seedController,
                  decoration: const InputDecoration(
                    labelText: '12 chiffres minimum',
                    hintText: 'Ex : 123456789012',
                  ),

                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _generateForSeed,
                  child: const Text('Générer'),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],

                if (_generatedBarcode != null) ...[
                  const SizedBox(height: 20),
                  BarcodeWidget(
                    barcode: Barcode.ean13(),
                    data: _generatedBarcode!,
                    width: 300,
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
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final barcode = product.barcode;

                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            barcode == null
                                ? 'Pas de code-barres'
                                : 'Code-barres : $barcode',
                          ),

                          trailing: TextButton(
                            onPressed: barcode == null
                                ? null
                                : () => _useProductBarcode(barcode),
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
