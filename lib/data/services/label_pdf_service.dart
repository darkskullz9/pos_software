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
                  height: 130,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (brand.isNotEmpty)
                        pw.Text(
                          brand.toUpperCase(),
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: fontBold,
                            color: PdfColors.grey800,
                          ),
                        ),

                      if (brand.isNotEmpty) pw.SizedBox(height: 2),

                      pw.Text(
                        product.name,
                        maxLines: 2,
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: fontBold,
                        ),
                      ),

                      pw.SizedBox(height: 6),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              size != null ? 'Taille : $size' : '',
                              style: pw.TextStyle(
                                fontSize: 8,
                                font: fontRegular,
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            '${product.price.toStringAsFixed(2)} €',
                            style: pw.TextStyle(
                              fontSize: 11,
                              font: fontBold,
                            ),
                          ),
                        ],
                      ),

                      if (color != null) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Couleur : $color',
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 8,
                            font: fontRegular,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],

                      pw.Spacer(),

                      if (barcodeValue.isNotEmpty)
                        pw.Center(
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.code128(),
                            data: barcodeValue,
                            width: 135,
                            height: 34,
                            drawText: true,
                            textStyle: pw.TextStyle(
                              fontSize: 8,
                              font: fontRegular,
                            ),
                          ),
                        )
                      else
                        pw.Container(
                          alignment: pw.Alignment.center,
                          height: 34,
                          child: pw.Text(
                            'Code-barres indisponible',
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: fontRegular,
                              color: PdfColors.grey700,
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
      case 5:
        return 'Gris';
      default:
        return null;
    }
  }
}