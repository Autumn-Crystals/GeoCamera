import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/tree_model.dart';
import 'impact_calculator.dart';

class PdfCertificateService {
  static Future<void> generateAndPreviewCertificate(TreeRecord tree) async {
    final pdf = pw.Document();

    // 1. Load images
    pw.MemoryImage? treeImage;
    if (tree.imagePath.isNotEmpty) {
      final file = File(tree.imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        treeImage = pw.MemoryImage(bytes);
      }
    }

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/app_icon.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // 2. Build the Certificate Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#2E7D32'), width: 10), // Forest Green
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Center(
                    child: pw.Image(logoImage, width: 60, height: 60),
                  ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Tree Plantation Program',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'CERTIFICATE OF PLANTING',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This certificate is proudly presented to',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  tree.donorName.isNotEmpty ? tree.donorName : 'A Proud Supporter',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#388E3C'),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'for their invaluable contribution to a greener planet by planting a:',
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  tree.plantName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Tree Details & QR Code
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DETAILS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date Planted: ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(tree.dateTime))}'),
                        pw.Text('Location: ${tree.latitude.toStringAsFixed(6)}, ${tree.longitude.toStringAsFixed(6)}'),
                        if (tree.areaName != null && tree.areaName!.isNotEmpty)
                          pw.Text('Area: ${tree.areaName}'),
                        pw.SizedBox(height: 10),
                        pw.BarcodeWidget(
                          data: 'ngo-tree-tracker://tree/${tree.treeId}',
                          width: 60,
                          height: 60,
                          barcode: pw.Barcode.qrCode(),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Scan to view tree', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    // Tree Image
                    if (treeImage != null)
                      pw.Container(
                        width: 140,
                        height: 140,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 2),
                        ),
                        child: pw.Image(treeImage, fit: pw.BoxFit.cover),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // 3. Print / Share
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Certificate_${tree.treeId}.pdf',
    );
  }

  static Future<void> generateMasterCertificate(String donor, List<TreeRecord> trees) async {
    final pdf = pw.Document();
    final totalCo2 = ImpactCalculator.calculateTotalCo2(trees);
    final co2Text = ImpactCalculator.formatCo2(totalCo2);
    
    final areas = trees.map((t) => t.areaName ?? '').where((a) => a.isNotEmpty).toSet().toList();
    areas.sort();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/app_icon.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#FBC02D'), width: 12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Center(child: pw.Image(logoImage, width: 60, height: 60)),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Environmental Impact Award',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#2E7D32'),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'ENVIRONMENTAL STEWARDSHIP AWARD',
                  style: pw.TextStyle(
                    fontSize: 34,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1B5E20'),
                  ),
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  'This prestigious award is presented to',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  donor,
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#FBC02D'),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'In recognition of their outstanding contribution to global reforestation.',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.Spacer(),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  color: PdfColor.fromHex('#E8F5E9'),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('TREES PLANTED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('${trees.length}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('CARBON SEQUESTERED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(co2Text, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#388E3C'))),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('AREAS PROTECTED', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('${areas.length}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date Issued: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}'),
                        pw.Text('Certificate ID: NIS-${donor.hashCode.toUnsigned(16)}'),
                      ],
                    ),
                    pw.BarcodeWidget(
                      data: 'https://example.org/donor/${Uri.encodeComponent(donor)}',
                      width: 50,
                      height: 50,
                      barcode: pw.Barcode.qrCode(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Master_Impact_${donor}.pdf',
    );
  }
}
