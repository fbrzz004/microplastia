import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService._();

  static final ImageStorageService instance = ImageStorageService._();

  static const String _folderName = 'microplastia/samples';

  Future<Directory> _getImageDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory(
      p.join(appDirectory.path, _folderName),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    return imageDirectory;
  }

  Future<String> saveImage({
    required Uint8List bytes,
    required String clientUuid,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('No se puede guardar una imagen vacía.');
    }

    final directory = await _getImageDirectory();

    final extension = p.extension(filename).toLowerCase().isEmpty
        ? '.jpg'
        : p.extension(filename).toLowerCase();

    final baseName = p.basenameWithoutExtension(filename);

    final file = File(
      p.join(
        directory.path,
        '${clientUuid}_$baseName$extension',
      ),
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
  }

  Future<bool> imageExists(String imagePath) {
    return File(imagePath).exists();
  }

  Future<Uint8List> readImage(String imagePath) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception('La imagen almacenada no existe.');
    }

    return file.readAsBytes();
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
