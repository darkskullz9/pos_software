import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cart_item_model.dart';

class ReceiptService {
  Future<Uint8List> buildReceiptPdf({
    required String storeName,
    required String currency,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double total,
    required double taxRate,
    String? footer,
    DateTime? date,
  }) async {
    final receiptDate = date ?? DateTime.now();

    final pdf = pw.Document();

    final pageHeight = _calculatePageHeight(items.length);
    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      pageHeight,
      marginAll: 4 * PdfPageFormat.mm,
    );

    final taxAmount = _calculateTaxAmount(total, taxRate);
    final totalWithoutTax = total - taxAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  storeName.trim().isEmpty ? 'Caisse' : storeName.trim(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Ticket de caisse',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  _formatDate(receiptDate),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Divider(),

              ...items.map((item) {
                final product = item.product;
                final brand = product.brand?.trim();
                final productName = brand == null || brand.isEmpty
                    ? product.name
                    : '$brand - ${product.name}';

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(
                        productName,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '${item.quantity} x ${_money(product.price, currency)}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            _money(item.subtotal, currency),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(),

              if (taxRate > 0) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total HT estimé',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      _money(totalWithoutTax, currency),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TVA ${taxRate.toStringAsFixed(2)}%',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      _money(taxAmount, currency),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
              ],

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL TTC',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _money(total, currency),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Paiement', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    paymentMethod,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),

              pw.Divider(),

              pw.Center(
                child: pw.Text(
                  footer?.trim().isEmpty ?? true
                      ? 'Merci pour votre achat'
                      : footer!.trim(),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> shareReceipt({
    required String storeName,
    required String currency,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double total,
    required double taxRate,
    String? footer,
    DateTime? date,
  }) async {
    final receiptDate = date ?? DateTime.now();

    final bytes = await buildReceiptPdf(
      storeName: storeName,
      currency: currency,
      paymentMethod: paymentMethod,
      items: items,
      total: total,
      taxRate: taxRate,
      footer: footer,
      date: receiptDate,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: _receiptFileName(receiptDate),
    );
  }

  Future<void> printReceipt({
    required String storeName,
    required String currency,
    required String paymentMethod,
    required List<CartItemModel> items,
    required double total,
    required double taxRate,
    String? footer,
    DateTime? date,
  }) async {
    final bytes = await buildReceiptPdf(
      storeName: storeName,
      currency: currency,
      paymentMethod: paymentMethod,
      items: items,
      total: total,
      taxRate: taxRate,
      footer: footer,
      date: date,
    );

    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  double _calculatePageHeight(int itemCount) {
    final minHeight = 180 * PdfPageFormat.mm;
    final estimatedHeight = (130 + itemCount * 14) * PdfPageFormat.mm;

    return estimatedHeight < minHeight ? minHeight : estimatedHeight;
  }

  double _calculateTaxAmount(double total, double taxRate) {
    if (taxRate <= 0) return 0;

    final rate = taxRate / 100;

    return total - (total / (1 + rate));
  }

  String _money(double value, String currency) {
    return '${value.toStringAsFixed(2)} $currency';
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  String _receiptFileName(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return 'ticket_${date.year}${two(date.month)}${two(date.day)}_'
        '${two(date.hour)}${two(date.minute)}${two(date.second)}.pdf';
  }
}
