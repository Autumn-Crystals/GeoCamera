import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/tree_model.dart';

class CertificateService {
  static Future<File> generateDonorCertificate({
    required String donorName,
    required List<TreeRecord> trees,
    required String certificateId,
  }) async {
    final pdf = pw.Document();

    // Calculate statistics
    final totalTrees = trees.length;
    final speciesCounts = <String, int>{};
    DateTime? earliestDate;
    DateTime? latestDate;

    for (var tree in trees) {
      speciesCounts[tree.plantName] = (speciesCounts[tree.plantName] ?? 0) + 1;
      
      final date = DateTime.tryParse(tree.dateTime);
      if (date != null) {
        if (earliestDate == null || date.isBefore(earliestDate)) {
          earliestDate = date;
        }
        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      }
    }

    // Sort species by count
    final sortedSpecies = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate environmental impact (rough estimates)
    final co2Offset = (totalTrees * 22).toStringAsFixed(0); // ~22kg CO2/tree/year
    final oxygenProduced = (totalTrees * 118).toStringAsFixed(0); // ~118kg O2/tree/year

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with border
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green700, width: 3),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  children: [
                    // Title
                    pw.Text(
                      'TREE PLANTATION CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Certificate of Appreciation',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.green700,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Certificate body
              pw.Text(
                'This is to certify that',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),

              // Donor name (highlighted)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Text(
                  donorName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'has made a significant contribution to environmental conservation by sponsoring the plantation of',
                style: const pw.TextStyle(fontSize: 14),
              ),

              pw.SizedBox(height: 15),

              // Tree count (highlighted)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green700,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Text(
                      '$totalTrees TREES',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Species breakdown
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Species Planted:',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    ...sortedSpecies.take(5).map((entry) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        children: [
                          pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                            '${entry.key}: ',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            '${entry.value} ${entry.value == 1 ? 'tree' : 'trees'}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (sortedSpecies.length > 5)
                      pw.Text(
                        '...and ${sortedSpecies.length - 5} more species',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Environmental impact
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Environmental Impact (Annual):',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              '🌍',
                              style: const pw.TextStyle(fontSize: 24),
                            ),
                            pw.Text(
                              '$co2Offset kg',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'CO₂ Absorbed',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              '💨',
                              style: const pw.TextStyle(fontSize: 24),
                            ),
                            pw.Text(
                              '$oxygenProduced kg',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Oxygen Produced',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Plantation Period:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        earliestDate != null && latestDate != null
                            ? '${DateFormat('dd MMM yyyy').format(earliestDate)} - ${DateFormat('dd MMM yyyy').format(latestDate)}'
                            : 'N/A',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Certificate ID:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        certificateId,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              pw.Divider(color: PdfColors.green300),

              pw.SizedBox(height: 10),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Issued by:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Tree Plantation Program',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        DateFormat('dd MMMM yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/certificate_${donorName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> shareCertificate(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  static Future<void> printCertificate(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await pdfFile.readAsBytes(),
    );
  }
}
