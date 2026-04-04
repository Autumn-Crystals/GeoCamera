import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImageStampService {
  static Future<Uint8List> stampImage({
    required Uint8List imageBytes,
    required String treeId,
    String? plantName,
    double? latitude,
    double? longitude,
    DateTime? dateTime,
  }) async {
    // Decode the image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final w = image.width.toDouble();
    final h = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Draw original image
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw gradient banner at bottom
    final bannerHeight = (h * 0.22).clamp(120.0, 300.0);
    final bannerRect = Rect.fromLTWH(0, h - bannerHeight - 20, w, bannerHeight + 20);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.88)],
      stops: const [0.0, 0.15, 1.0],
    );
    canvas.drawRect(bannerRect, Paint()..shader = gradient.createShader(bannerRect));

    // Accent line
    canvas.drawRect(
      Rect.fromLTWH(16, h - bannerHeight + 8, 50, 3),
      Paint()..color = const Color(0xFF34D399),
    );

    final baseFontSize = (w / 42).clamp(13.0, 28.0);
    var textY = h - bannerHeight + 26;
    final lineSpacing = baseFontSize * 1.55;

    // Tree ID
    _drawText(canvas, '🌳  $treeId', 20, textY, baseFontSize + 2, const Color(0xFF34D399), w, fontWeight: FontWeight.bold);
    textY += lineSpacing;

    // Plant name
    if (plantName != null) {
      _drawText(canvas, '🌱  $plantName', 20, textY, baseFontSize, Colors.white, w, fontWeight: FontWeight.w600);
      textY += lineSpacing;
    }

    // Coordinates
    final lat = latitude?.toStringAsFixed(6) ?? '—';
    final lng = longitude?.toStringAsFixed(6) ?? '—';
    _drawText(canvas, '📍  $lat, $lng', 20, textY, baseFontSize, Colors.white.withValues(alpha: 0.9), w);
    textY += lineSpacing;

    // Date & Time
    final dt = dateTime ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(dt);
    final timeStr = DateFormat('hh:mm:ss a').format(dt);
    _drawText(canvas, '📅  $dateStr  •  🕐  $timeStr', 20, textY, baseFontSize, Colors.white.withValues(alpha: 0.9), w);

    // Watermark
    _drawText(canvas, '📷  निसर्गवैद्य', w - 180, h - 24, baseFontSize - 2, const Color(0x9934D399), w);

    // Encode to PNG
    final picture = recorder.endRecording();
    final stampedImage = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await stampedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color, double maxWidth, {FontWeight fontWeight = FontWeight.normal}) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: fontSize, fontWeight: fontWeight),
    )
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight, shadows: [
        const Shadow(color: Colors.black54, blurRadius: 4),
      ]))
      ..addText(text);
    final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: maxWidth - x - 10));
    canvas.drawParagraph(paragraph, Offset(x, y));
  }

  static double _measureText(String text, double fontSize) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: fontSize))
      ..addText(text);
    final p = builder.build()..layout(const ui.ParagraphConstraints(width: 1000));
    return p.longestLine;
  }
}
