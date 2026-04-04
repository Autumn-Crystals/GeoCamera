import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/tree_model.dart';
import 'database_service.dart';
import 'local_file_service.dart';

class SyncService {
  static const String _pendingSyncKey = 'pending_sync_items';
  static const String _lastSyncKey = 'last_sync_time';

  // Check if device is online
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  // Queue an item for sync when online
  static Future<void> queueForSync(SyncItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingSyncKey) ?? [];
    existing.add(jsonEncode(item.toMap()));
    await prefs.setStringList(_pendingSyncKey, existing);
  }

  // Get pending sync count
  static Future<int> getPendingSyncCount() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingSyncKey) ?? [];
    return existing.length;
  }

  // Get all pending items
  static Future<List<SyncItem>> getPendingItems() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingSyncKey) ?? [];
    return existing.map((s) => SyncItem.fromMap(jsonDecode(s))).toList();
  }

  // Sync all pending items
  static Future<SyncResult> syncPendingItems() async {
    if (!await isOnline()) {
      return SyncResult(success: false, message: 'No internet connection', synced: 0);
    }

    final items = await getPendingItems();
    if (items.isEmpty) {
      return SyncResult(success: true, message: 'Nothing to sync', synced: 0);
    }

    int synced = 0;
    final List<String> errors = [];

    for (var item in items) {
      try {
        // In a real app, you'd upload to Firebase/server here
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate network

        // Once successful, update local DB to synced (1)
        final db = await DatabaseService.db;
        if (item.type == 'tree') {
          await db.update('trees', {'syncStatus': 1}, where: 'treeId = ?', whereArgs: [item.id]);
        } else if (item.type == 'update') {
          await db.update('tree_updates', {'syncStatus': 1}, where: 'updateId = ?', whereArgs: [item.id]);
        }

        // Extremely aggressively crush the massive photo down to a thumbnail!
        final imagePath = item.data['imagePath'] as String?;
        if (imagePath != null && imagePath.isNotEmpty) {
          await LocalFileService.compressToThumbnail(imagePath);
        }

        synced++;
      } catch (e) {
        errors.add('Failed to sync ${item.type}: ${item.id}');
      }
    }

    // Clear synced items
    if (synced > 0) {
      await _clearSyncedItems(synced);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    }

    return SyncResult(
      success: errors.isEmpty,
      message: errors.isEmpty
          ? 'Synced $synced items successfully'
          : 'Synced $synced items with ${errors.length} errors',
      synced: synced,
      errors: errors,
    );
  }

  static Future<void> _clearSyncedItems(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingSyncKey) ?? [];
    final remaining = existing.skip(count).toList();
    await prefs.setStringList(_pendingSyncKey, remaining);
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastSyncKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  // Clear all pending items (use with caution)
  static Future<void> clearAllPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSyncKey);
  }
}

class SyncItem {
  final String id;
  final String type; // 'tree' or 'update'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncItem.fromMap(Map<String, dynamic> map) => SyncItem(
        id: map['id'],
        type: map['type'],
        data: Map<String, dynamic>.from(map['data']),
        timestamp: DateTime.parse(map['timestamp']),
      );
}

class SyncResult {
  final bool success;
  final String message;
  final int synced;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.synced,
    this.errors = const [],
  });
}
