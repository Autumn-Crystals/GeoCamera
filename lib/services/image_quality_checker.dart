import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageQualityResult {
  final bool isAcceptable;
  final double qualityScore; // 0-100
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> metrics;

  ImageQualityResult({
    required this.isAcceptable,
    required this.qualityScore,
    required this.issues,
    required this.warnings,
    required this.metrics,
  });

  String getSummary() {
    if (isAcceptable) {
      return 'Good quality image (${qualityScore.toStringAsFixed(0)}/100)';
    } else {
      return 'Quality issues detected: ${issues.join(", ")}';
    }
  }
}

class ImageQualityChecker {
  // Minimum acceptable values
  static const int minWidth = 480;
  static const int minHeight = 640;
  static const int minBrightness = 30;
  static const int maxBrightness = 240;
  static const double minSharpness = 10.0;
  static const int minFileSize = 50 * 1024; // 50 KB
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB

  // Check image quality
  static Future<ImageQualityResult> checkQuality(String imagePath) async {
    final issues = <String>[];
    final warnings = <String>[];
    final metrics = <String, dynamic>{};
    double qualityScore = 100.0;

    try {
      final file = File(imagePath);
      
      // Check file size
      final fileSize = await file.length();
      metrics['fileSize'] = fileSize;
      
      if (fileSize < minFileSize) {
        issues.add('File too small (${(fileSize / 1024).toStringAsFixed(0)} KB)');
        qualityScore -= 30;
      } else if (fileSize > maxFileSize) {
        warnings.add('Large file size (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB)');
        qualityScore -= 5;
      }

      // Read and decode image
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        issues.add('Unable to decode image');
        return ImageQualityResult(
          isAcceptable: false,
          qualityScore: 0,
          issues: issues,
          warnings: warnings,
          metrics: metrics,
        );
      }

      // Check resolution
      metrics['width'] = image.width;
      metrics['height'] = image.height;
      metrics['megapixels'] = (image.width * image.height / 1000000).toStringAsFixed(1);

      if (image.width < minWidth || image.height < minHeight) {
        issues.add('Low resolution (${image.width}x${image.height})');
        qualityScore -= 25;
      }

      // Check brightness
      final brightness = _calculateBrightness(image);
      metrics['brightness'] = brightness.toStringAsFixed(0);

      if (brightness < minBrightness) {
        issues.add('Image too dark');
        qualityScore -= 20;
      } else if (brightness > maxBrightness) {
        issues.add('Image too bright/overexposed');
        qualityScore -= 20;
      } else if (brightness < 60) {
        warnings.add('Slightly dark');
        qualityScore -= 5;
      } else if (brightness > 200) {
        warnings.add('Slightly bright');
        qualityScore -= 5;
      }

      // Check sharpness (blur detection)
      final sharpness = _calculateSharpness(image);
      metrics['sharpness'] = sharpness.toStringAsFixed(1);

      if (sharpness < minSharpness) {
        issues.add('Image is blurry');
        qualityScore -= 25;
      } else if (sharpness < 20) {
        warnings.add('Slightly blurry');
        qualityScore -= 10;
      }

      // Check contrast
      final contrast = _calculateContrast(image);
      metrics['contrast'] = contrast.toStringAsFixed(1);

      if (contrast < 20) {
        warnings.add('Low contrast');
        qualityScore -= 5;
      }

      // Check if image is mostly one color (likely error)
      final colorVariance = _calculateColorVariance(image);
      metrics['colorVariance'] = colorVariance.toStringAsFixed(1);

      if (colorVariance < 100) {
        issues.add('Image lacks detail (uniform color)');
        qualityScore -= 20;
      }

      qualityScore = qualityScore.clamp(0, 100);

      return ImageQualityResult(
        isAcceptable: issues.isEmpty,
        qualityScore: qualityScore,
        issues: issues,
        warnings: warnings,
        metrics: metrics,
      );
    } catch (e) {
      return ImageQualityResult(
        isAcceptable: false,
        qualityScore: 0,
        issues: ['Error analyzing image: $e'],
        warnings: [],
        metrics: {},
      );
    }
  }

  // Calculate average brightness
  static double _calculateBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;

    // Sample every 10th pixel for performance
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Calculate perceived brightness
        totalBrightness += ((r * 299 + g * 587 + b * 114) / 1000).round();
        pixelCount++;
      }
    }

    return pixelCount > 0 ? totalBrightness / pixelCount : 0;
  }

  // Calculate sharpness using Laplacian variance (blur detection)
  static double _calculateSharpness(img.Image image) {
    // Convert to grayscale for edge detection
    final gray = img.grayscale(image);
    
    double variance = 0;
    int count = 0;

    // Sample center region for performance
    final startX = gray.width ~/ 4;
    final endX = (gray.width * 3) ~/ 4;
    final startY = gray.height ~/ 4;
    final endY = (gray.height * 3) ~/ 4;

    // Apply Laplacian kernel
    for (int y = startY + 1; y < endY - 1; y += 5) {
      for (int x = startX + 1; x < endX - 1; x += 5) {
        final center = gray.getPixel(x, y).r.toInt();
        final top = gray.getPixel(x, y - 1).r.toInt();
        final bottom = gray.getPixel(x, y + 1).r.toInt();
        final left = gray.getPixel(x - 1, y).r.toInt();
        final right = gray.getPixel(x + 1, y).r.toInt();

        final laplacian = (4 * center - top - bottom - left - right).abs();
        variance += laplacian * laplacian;
        count++;
      }
    }

    return count > 0 ? variance / count : 0;
  }

  // Calculate contrast
  static double _calculateContrast(img.Image image) {
    int minBrightness = 255;
    int maxBrightness = 0;

    // Sample pixels
    for (int y = 0; y < image.height; y += 20) {
      for (int x = 0; x < image.width; x += 20) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        final brightness = ((r * 299 + g * 587 + b * 114) / 1000).round();
        
        if (brightness < minBrightness) minBrightness = brightness;
        if (brightness > maxBrightness) maxBrightness = brightness;
      }
    }

    return (maxBrightness - minBrightness).toDouble();
  }

  // Calculate color variance
  static double _calculateColorVariance(img.Image image) {
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];

    // Sample pixels
    for (int y = 0; y < image.height; y += 15) {
      for (int x = 0; x < image.width; x += 15) {
        final pixel = image.getPixel(x, y);
        rValues.add(pixel.r.toInt());
        gValues.add(pixel.g.toInt());
        bValues.add(pixel.b.toInt());
      }
    }

    final rVariance = _variance(rValues);
    final gVariance = _variance(gValues);
    final bVariance = _variance(bValues);

    return (rVariance + gVariance + bVariance) / 3;
  }

  // Calculate variance of a list
  static double _variance(List<int> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  // Quick check (faster, less thorough)
  static Future<bool> quickCheck(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileSize = await file.length();

      if (fileSize < minFileSize || fileSize > maxFileSize) {
        return false;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return false;
      if (image.width < minWidth || image.height < minHeight) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}
