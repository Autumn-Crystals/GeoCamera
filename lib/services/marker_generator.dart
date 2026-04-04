import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/tree_model.dart';
import '../models/map_models.dart';
import 'health_calculator.dart';

class MarkerGenerator {
  // LRU cache for generated markers (max 50 entries)
  static final Map<String, BitmapDescriptor> _cache = {};
  static final List<String> _cacheKeys = [];
  static const int _maxCacheSize = 50;

  // Generate cache key from marker properties
  static String _cacheKey(Color color, double size, bool shouldPulse) {
    // Quantize size to 4px increments to reduce cache variations
    final quantizedSize = (size / 4).round() * 4;
    return '${color.value}_${quantizedSize}_$shouldPulse';
  }

  // Clear the marker cache
  static void clearCache() {
    _cache.clear();
    _cacheKeys.clear();
  }

  // Create circular marker with specified properties
  static Future<BitmapDescriptor> createCircularMarker({
    required Color color,
    required double size,
    bool shouldPulse = false,
  }) async {
    final key = _cacheKey(color, size, shouldPulse);

    // Return cached marker if available
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Create new marker using Canvas
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;

    // Draw outer circle (pulse effect for critical markers)
    if (shouldPulse) {
      final pulsePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2,
        pulsePaint,
      );
    }

    // Draw main circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final bitmapDescriptor = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

    // Cache the marker with LRU eviction
    _cache[key] = bitmapDescriptor;
    _cacheKeys.add(key);

    // Enforce cache size limit
    if (_cacheKeys.length > _maxCacheSize) {
      final oldestKey = _cacheKeys.removeAt(0);
      _cache.remove(oldestKey);
    }

    return bitmapDescriptor;
  }

  // Create cluster marker with count label
  static Future<BitmapDescriptor> createClusterMarker({
    required Color color,
    required int count,
    required double size,
  }) async {
    final key = 'cluster_${color.value}_${count}_$size';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw circle
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );

    // Draw count text
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size / 3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final bitmapDescriptor = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());

    _cache[key] = bitmapDescriptor;
    _cacheKeys.add(key);

    if (_cacheKeys.length > _maxCacheSize) {
      final oldestKey = _cacheKeys.removeAt(0);
      _cache.remove(oldestKey);
    }

    return bitmapDescriptor;
  }

  // Calculate marker size based on update count
  static double calculateMarkerSize(int updateCount) {
    const baseSize = 48.0; // Much bigger base size
    final size = baseSize + (updateCount * 2.0);
    return size.clamp(48.0, 72.0); // Range: 48-72 pixels
  }

  // Generate markers for a list of trees
  static Future<Set<Marker>> generateMarkersForTrees(
    List<TreeRecord> trees,
    Function(String treeId) onTap,
  ) async {
    final markers = <Marker>{};

    for (final tree in trees) {
      // Calculate health status
      final healthStatus = HealthCalculator.calculateHealth(tree);

      // Determine marker size based on update count
      final markerSize = calculateMarkerSize(tree.updates.length);

      // Critical trees get pulsing animation
      final shouldPulse = healthStatus.status == HealthStatus.critical;

      // Generate or retrieve cached marker icon
      final markerIcon = await createCircularMarker(
        color: healthStatus.color,
        size: markerSize,
        shouldPulse: shouldPulse,
      );

      // Format snippet for info window with plantation date
      final plantDate = DateTime.tryParse(tree.dateTime);
      final dateStr = plantDate != null
          ? '${plantDate.day}/${plantDate.month}/${plantDate.year}'
          : tree.dateTime;
      final snippet = 'Planted on $dateStr';

      // Create marker
      final marker = Marker(
        markerId: MarkerId(tree.treeId),
        position: LatLng(tree.latitude, tree.longitude),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: tree.plantName,
          snippet: snippet,
          onTap: () => onTap(tree.treeId),
        ),
      );

      markers.add(marker);
    }

    return markers;
  }
}
