import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/label_item_model.dart';

class LabelPdfService {
  Future<Uint8List> generateLabelsPdf(List<LabelItemModel> items) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );

    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );

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
                final barcodeValue = (product.barcode ?? '').trim();

                return pw.Container(
                  width: 165,
                  height: 110,
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
                          font: fontBold,
                        ),
                      ),

                      pw.Text(
                        '${product.price.toStringAsFixed(2)} €',
                        style: pw.TextStyle(
                          fontSize: 9,
                          font: fontRegular,
                        ),
                      ),

                      pw.SizedBox(height: 4),
                      if(barcodeValue.isNotEmpty) 
                        pw.Center(
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.code128(),
                            data: barcodeValue,
                            width: 140,
                            height: 32,
                            drawText: true,
                            textStyle: pw.TextStyle(
                              fontSize: 8,
                              font: fontRegular
                            ),
                          ),
                        ) 
                      else
                        pw.Container(
                          alignment: pw.Alignment.center,
                          height: 32,
                          child: pw.Text(
                            'Code-barres indisponible',
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: fontRegular
                            ),
                          ),
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