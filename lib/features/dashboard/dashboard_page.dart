import 'package:flutter/material.dart';

import '../../data/services/product_service.dart';

class DashboardPage extends StatelessWidget {
  final ProductService productService;

  const DashboardPage({
    super.key,
    required this.productService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: productService,
      builder: (context, child) {
        return GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _DashboardCard(
              title: 'Ventes',
              value: '${productService.salesTotal.toStringAsFixed(2)} €',
              subtitle: productService.salesTotal == 0 
                ? 'Aucune vente enregistrée'
                : 'Ventes encaissées',
            ),

            _DashboardCard(
              title: 'Produits en stock',
              value: '${productService.totalStock}',
              subtitle: productService.totalStock == 0 
                ? 'Aucun produit en stock' 
                : 'Stock disponible',
            ),

            _DashboardCard(
              title: 'Panier actuel',
              value: '${productService.currentCartCount}',
              subtitle: productService.currentCartCount == 0 
                ? 'Aucun article ajouté' 
                : 'Articles dans le panier',
            ),
          ],
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium),

            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}