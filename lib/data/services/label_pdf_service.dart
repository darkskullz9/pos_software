import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/label_item_model.dart';

class LabelPdfService {
  Future<Uint8List> generatLabelsPdf(List<LabelItemModel> items) async {
    final pdf = pw.Document();

    final labels = <LabelItemModel>[];
    for(final item in items) {
      for(int i = 0; i < item.quantity; i++) {
        labels.add(
          LabelItemModel(
            product: item.product, 
            quantity: 1,
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: labels.map((item) {
                final product = item.product;

                return pw.Container(
                  width: 165,
                  height: 100,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700),
                  ),

                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        product.name,
                        maxLines: 2,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}