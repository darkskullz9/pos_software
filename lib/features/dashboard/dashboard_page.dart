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
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: const [
        _DashboardCard(
          title: 'Ventes',
          value: '0,00 €',
          subtitle: 'Aucune vente enregistrée',
        ),

        _DashboardCard(
          title: 'Produits en stock',
          value: '0',
          subtitle: 'Aucun produit en stock',
        ),

        _DashboardCard(
          title: 'Panier actuel',
          value: '0',
          subtitle: 'Aucun article ajouté',
        ),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 12),

            Text(value, style: Theme.of(context).textTheme.headlineMedium),

            const Spacer(),

            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}