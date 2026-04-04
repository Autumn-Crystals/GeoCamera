import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

class LocalFileService {
  static final _uuid = const Uuid();

  static Future<String> saveImageBytes(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${_uuid.v4()}.png';
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> deleteImage(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<void> compressToThumbnail(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final thumbnail = img.copyResize(image, width: 400); // Drastically shrink
          final compressedBytes = img.encodeJpg(thumbnail, quality: 60);
          await file.writeAsBytes(compressedBytes);
        }
      }
    } catch (e) {
      print('Thumbnail compression failed: $e');
    }
  }
}
