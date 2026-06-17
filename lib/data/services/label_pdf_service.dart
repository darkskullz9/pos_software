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
    for (final item in items) {
      for (int i = 0; i < item.quantity; i++) {
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
                final brand = (product.brand ?? '').trim();
                final size = _sizeLabel(product.sizeCode);
                final color = _colorLabel(product.colorCode);

                return pw.Container(
                  width: 165,
                  height: 145,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(
                      color: PdfColors.grey500,
                      width: 0.8,
                    ),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      if (brand.isNotEmpty)
                        pw.Text(
                          brand.toUpperCase(),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: fontBold,
                            letterSpacing: 1,
                            color: PdfColors.grey800,
                          ),
                        ),

                      if (brand.isNotEmpty) pw.SizedBox(height: 4),

                      pw.Text(
                        product.name,
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: fontBold,
                          color: PdfColors.black,
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (size != null)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(10),
                                ),
                              ),
                              child: pw.Text(
                                size,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  font: fontBold,
                                  color: PdfColors.black,
                                ),
                              ),
                            )
                          else
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                border: pw.Border.all(
                                  color: PdfColors.grey300,
                                  width: 0.5,
                                ),
                                borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(10),
                                ),
                              ),
                              child: pw.Text(
                                '-',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  font: fontRegular,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ),

                          pw.Spacer(),

                          pw.Text(
                            '${product.price.toStringAsFixed(2)} €',
                            style: pw.TextStyle(
                              fontSize: 12,
                              font: fontBold,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),

                      if (color != null) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          color,
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: fontRegular,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],

                      pw.Spacer(),

                      pw.Container(
                        padding: const pw.EdgeInsets.fromLTRB(6, 6, 6, 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: barcodeValue.isNotEmpty
                            ? pw.Column(
                                children: [
                                  pw.BarcodeWidget(
                                    barcode: pw.Barcode.code128(),
                                    data: barcodeValue,
                                    width: 130,
                                    height: 32,
                                    drawText: true,
                                    textStyle: pw.TextStyle(
                                      fontSize: 7,
                                      font: fontRegular,
                                    ),
                                  ),
                                ],
                              )
                            : pw.Container(
                                alignment: pw.Alignment.center,
                                height: 34,
                                child: pw.Text(
                                  'Code-barres indisponible',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    font: fontRegular,
                                    color: PdfColors.grey700,
                                  ),
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

  String? _sizeLabel(int? code) {
    switch (code) {
      case 1:
        return 'XS';
      case 2:
        return 'S';
      case 3:
        return 'M';
      case 4:
        return 'L';
      case 5:
        return 'XL';
      default:
        return null;
    }
  }

  String? _colorLabel(int? code) {
    switch (code) {
      case 1:
        return 'Noir';
      case 2:
        return 'Blanc';
      case 3:
        return 'Bleu';
      case 4:
        return 'Rouge';
      default:
        return null;
    }
  }
}