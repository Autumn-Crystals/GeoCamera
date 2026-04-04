import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QueuedPhoto {
  final String id;
  final String localPath;
  final String treeId;
  final String type; // 'initial' or 'update'
  final DateTime queuedAt;
  final Map<String, dynamic> metadata;

  QueuedPhoto({
    required this.id,
    required this.localPath,
    required this.treeId,
    required this.type,
    required this.queuedAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'localPath': localPath,
    'treeId': treeId,
    'type': type,
    'queuedAt': queuedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory QueuedPhoto.fromJson(Map<String, dynamic> json) => QueuedPhoto(
    id: json['id'],
    localPath: json['localPath'],
    treeId: json['treeId'],
    type: json['type'],
    queuedAt: DateTime.parse(json['queuedAt']),
    metadata: json['metadata'] ?? {},
  );
}

class PhotoQueueService {
  static const String _queueKey = 'photo_upload_queue';
  static bool _isUploading = false;

  // Add photo to upload queue
  static Future<void> queuePhoto({
    required String localPath,
    required String treeId,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getQueue();

    final queuedPhoto = QueuedPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      localPath: localPath,
      treeId: treeId,
      type: type,
      queuedAt: DateTime.now(),
      metadata: metadata ?? {},
    );

    queue.add(queuedPhoto);
    await _saveQueue(queue);

    // Try to upload immediately if online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.mobile) || 
        connectivity.contains(ConnectivityResult.wifi)) {
      processQueue();
    }
  }

  // Get all queued photos
  static Future<List<QueuedPhoto>> getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    
    if (queueJson == null) return [];

    final List<dynamic> queueList = json.decode(queueJson);
    return queueList.map((item) => QueuedPhoto.fromJson(item)).toList();
  }

  // Save queue to storage
  static Future<void> _saveQueue(List<QueuedPhoto> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = json.encode(queue.map((q) => q.toJson()).toList());
    await prefs.setString(_queueKey, queueJson);
  }

  // Process upload queue
  static Future<void> processQueue() async {
    if (_isUploading) return;
    _isUploading = true;

    try {
      final queue = await getQueue();
      if (queue.isEmpty) {
        _isUploading = false;
        return;
      }

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.contains(ConnectivityResult.mobile) && 
          !connectivity.contains(ConnectivityResult.wifi)) {
        _isUploading = false;
        return;
      }

      final successfulUploads = <String>[];

      for (var photo in queue) {
        try {
          // Check if file still exists
          final file = File(photo.localPath);
          if (!await file.exists()) {
            successfulUploads.add(photo.id);
            continue;
          }

          // Upload photo to server/cloud
          final uploaded = await _uploadPhoto(photo);
          
          if (uploaded) {
            successfulUploads.add(photo.id);
          }
        } catch (e) {
          print('Error uploading photo ${photo.id}: $e');
          // Continue with next photo
        }
      }

      // Remove successfully uploaded photos from queue
      if (successfulUploads.isNotEmpty) {
        final updatedQueue = queue.where((p) => !successfulUploads.contains(p.id)).toList();
        await _saveQueue(updatedQueue);
      }
    } finally {
      _isUploading = false;
    }
  }

  // Upload single photo (implement actual upload logic here)
  static Future<bool> _uploadPhoto(QueuedPhoto photo) async {
    // TODO: Implement actual upload to your backend/cloud storage
    // For now, simulate upload with delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In real implementation:
    // 1. Read file bytes
    // 2. Upload to Firebase Storage / AWS S3 / your backend
    // 3. Update database with remote URL
    // 4. Return true on success
    
    print('Uploading photo: ${photo.id} for tree: ${photo.treeId}');
    return true; // Simulate success
  }

  // Get queue size
  static Future<int> getQueueSize() async {
    final queue = await getQueue();
    return queue.length;
  }

  // Clear entire queue (use with caution)
  static Future<void> clearQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
  }

  // Remove specific photo from queue
  static Future<void> removeFromQueue(String photoId) async {
    final queue = await getQueue();
    final updatedQueue = queue.where((p) => p.id != photoId).toList();
    await _saveQueue(updatedQueue);
  }

  // Get total size of queued photos
  static Future<double> getQueueSizeMB() async {
    final queue = await getQueue();
    int totalBytes = 0;

    for (var photo in queue) {
      final file = File(photo.localPath);
      if (await file.exists()) {
        totalBytes += await file.length();
      }
    }

    return totalBytes / (1024 * 1024); // Convert to MB
  }

  // Check if currently uploading
  static bool isUploading() => _isUploading;
}
