import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/tree_model.dart';
import 'database_service.dart';

class ExportService {
  // Export all data to CSV
  static Future<File> exportToCSV() async {
    final trees = await DatabaseService.getTrees();
    
    // Prepare CSV data
    List<List<dynamic>> rows = [
      [
        'Tree ID',
        'Plant Name',
        'Donor Name',
        'Area',
        'Latitude',
        'Longitude',
        'Plantation Date',
        'Created By',
        'Total Updates',
        'Latest Update Date',
        'Latest Condition',
        'Remarks',
      ]
    ];

    for (var tree in trees) {
      rows.add([
        tree.treeId,
        tree.plantName,
        tree.donorName,
        tree.areaName ?? '',
        tree.latitude,
        tree.longitude,
        _formatDate(tree.dateTime),
        tree.createdBy,
        tree.updates.length,
        tree.updates.isNotEmpty ? _formatDate(tree.updates.last.dateTime) : '',
        tree.updates.isNotEmpty ? tree.updates.last.condition : '',
        tree.remarks ?? '',
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/geocamera_export_$timestamp.csv');
    await file.writeAsString(csv);

    return file;
  }

  // Export all data to Excel
  static Future<File> exportToExcel() async {
    final trees = await DatabaseService.getTrees();
    var excel = Excel.createExcel();
    
    // Create Trees sheet
    Sheet treesSheet = excel['Trees'];
    
    // Add headers
    treesSheet.appendRow([
      TextCellValue('Tree ID'),
      TextCellValue('Plant Name'),
      TextCellValue('Donor Name'),
      TextCellValue('Area'),
      TextCellValue('Latitude'),
      TextCellValue('Longitude'),
      TextCellValue('Plantation Date'),
      TextCellValue('Created By'),
      TextCellValue('Total Updates'),
      TextCellValue('Latest Update Date'),
      TextCellValue('Latest Condition'),
      TextCellValue('Remarks'),
    ]);

    // Add tree data
    for (var tree in trees) {
      treesSheet.appendRow([
        TextCellValue(tree.treeId),
        TextCellValue(tree.plantName),
        TextCellValue(tree.donorName),
        TextCellValue(tree.areaName ?? ''),
        DoubleCellValue(tree.latitude),
        DoubleCellValue(tree.longitude),
        TextCellValue(_formatDate(tree.dateTime)),
        TextCellValue(tree.createdBy),
        IntCellValue(tree.updates.length),
        TextCellValue(tree.updates.isNotEmpty ? _formatDate(tree.updates.last.dateTime) : ''),
        TextCellValue(tree.updates.isNotEmpty ? tree.updates.last.condition : ''),
        TextCellValue(tree.remarks ?? ''),
      ]);
    }

    // Create Updates sheet
    Sheet updatesSheet = excel['Updates'];
    updatesSheet.appendRow([
      TextCellValue('Update ID'),
      TextCellValue('Tree ID'),
      TextCellValue('Plant Name'),
      TextCellValue('Update Date'),
      TextCellValue('Condition'),
      TextCellValue('Height'),
      TextCellValue('Remarks'),
      TextCellValue('Updated By'),
    ]);

    for (var tree in trees) {
      for (var update in tree.updates) {
        updatesSheet.appendRow([
          TextCellValue(update.updateId),
          TextCellValue(tree.treeId),
          TextCellValue(tree.plantName),
          TextCellValue(_formatDate(update.dateTime)),
          TextCellValue(update.condition),
          TextCellValue(update.height),
          TextCellValue(update.remarks),
          TextCellValue(update.updatedBy),
        ]);
      }
    }

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/geocamera_export_$timestamp.xlsx');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  // Export and share CSV
  static Future<void> exportAndShareCSV() async {
    final file = await exportToCSV();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'GeoCamera Data Export - ${_formatDate(DateTime.now().toIso8601String())}',
      text: 'Tree plantation data exported from GeoCamera app',
    );
  }

  // Export and share Excel
  static Future<void> exportAndShareExcel() async {
    final file = await exportToExcel();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'GeoCamera Data Export - ${_formatDate(DateTime.now().toIso8601String())}',
      text: 'Tree plantation data exported from GeoCamera app',
    );
  }

  // Create backup JSON
  static Future<File> createBackup() async {
    final trees = await DatabaseService.getTrees();
    final stats = await DatabaseService.getStats();
    
    final backup = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'stats': stats,
      'trees': trees.map((t) => {
        ...t.toMap(),
        'updates': t.updates.map((u) => u.toMap()).toList(),
      }).toList(),
    };

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/geocamera_backup_$timestamp.json');
    
    await file.writeAsString(jsonEncode(backup));
    return file;
  }

  // Share backup
  static Future<void> shareBackup() async {
    final file = await createBackup();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'GeoCamera Backup - ${_formatDate(DateTime.now().toIso8601String())}',
      text: 'Complete backup of GeoCamera data',
    );
  }

  // Helper to format dates
  static String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
