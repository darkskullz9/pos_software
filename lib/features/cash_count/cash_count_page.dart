import 'package:flutter/material.dart';

import '../../data/models/sale_model.dart';
import '../../data/services/product_service.dart';
import '../../data/services/settings_service.dart';

class CashCountPage extends StatefulWidget {
  final ProductService productService;
  final SettingsService settingsService;

  const CashCountPage({
    super.key,
    required this.productService,
    required this.settingsService,
  });

  @override
  State<CashCountPage> createState() => _CashCountPageState();
}

class _CashCountPageState extends State<CashCountPage> {
  late final ProductService _productService;
  late final SettingsService _settingsService;

  final TextEditingController _openingCashController = TextEditingController();
  final TextEditingController _countedCashController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _productService = widget.productService;
    _settingsService = widget.settingsService;

    _productService.loadTodaySales();
  }

  @override
  void dispose() {
    _openingCashController.dispose();
    _countedCashController.dispose();

    super.dispose();
  }

  double _parseMoney(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double _totalForPaymentMethod(List<SaleModel> sales, String paymentMethod) {
    return sales
        .where((sale) => sale.paymentMethod == paymentMethod)
        .fold(0, (sum, sale) => sum + sale.total);
  }

  double get _openingCash => _parseMoney(_openingCashController.text);

  double get _countedCash => _parseMoney(_countedCashController.text);

  String _money(double value) {
    return '${value.toStringAsFixed(2)} ${_settingsService.settings.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _productService,
      builder: (context, _) {
        final sales = _productService.sales;

        final totalSales = sales.fold<double>(
          0,
          (sum, sale) => sum + sale.total,
        );

        final cashSales = _totalForPaymentMethod(sales, 'Espèces');
        final cardSales = _totalForPaymentMethod(sales, 'Carte bancaire');
        final transferSales = _totalForPaymentMethod(sales, 'Virement');
        final otherSales = _totalForPaymentMethod(sales, 'Autre');

        final expectedCash = _openingCash + cashSales;
        final difference = _countedCash - expectedCash;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'Ventes du jour',
                    value: _money(totalSales),
                    icon: Icons.today,
                  ),
                  _SummaryCard(
                    title: 'Nombre de ventes',
                    value: sales.length.toString(),
                    icon: Icons.receipt_long,
                  ),
                  _SummaryCard(
                    title: 'Espèces',
                    value: _money(cashSales),
                    icon: Icons.payments,
                  ),
                  _SummaryCard(
                    title: 'Carte bancaire',
                    value: _money(cardSales),
                    icon: Icons.credit_card,
                  ),
                  _SummaryCard(
                    title: 'Virement',
                    value: _money(transferSales),
                    icon: Icons.account_balance,
                  ),
                  _SummaryCard(
                    title: 'Autre',
                    value: _money(otherSales),
                    icon: Icons.more_horiz,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Comptage espèces',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: _productService.loadTodaySales,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _openingCashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Fond de caisse',
                                helperText: 'Montant présent au départ',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _countedCashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Espèces comptées',
                                helperText: 'Montant réel dans la caisse',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _CashLine(
                        label: 'Fond de caisse',
                        value: _money(_openingCash),
                      ),
                      _CashLine(
                        label: 'Ventes en espèces',
                        value: _money(cashSales),
                      ),
                      const Divider(),
                      _CashLine(
                        label: 'Espèces attendues',
                        value: _money(expectedCash),
                        isStrong: true,
                      ),
                      _CashLine(
                        label: 'Espèces comptées',
                        value: _money(_countedCash),
                      ),
                      const Divider(),
                      _CashLine(
                        label: 'Écart de caisse',
                        value: _money(difference),
                        isStrong: true,
                        valueColor: difference == 0
                            ? Colors.green
                            : difference < 0
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détail des ventes du jour',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (sales.isEmpty)
                        const Text('Aucune vente enregistrée aujourd’hui.')
                      else
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Heure')),
                            DataColumn(label: Text('Paiement')),
                            DataColumn(label: Text('Total')),
                          ],
                          rows: sales.map((sale) {
                            return DataRow(
                              cells: [
                                DataCell(Text(_formatTime(sale.createdAt))),
                                DataCell(Text(sale.paymentMethod)),
                                DataCell(Text(_money(sale.total))),
                              ],
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.hour)}:${two(date.minute)}';
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isStrong;
  final Color? valueColor;

  const _CashLine({
    required this.label,
    required this.value,
    this.isStrong = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = isStrong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
