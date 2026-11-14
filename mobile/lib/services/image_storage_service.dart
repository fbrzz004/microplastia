
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  ImageStorageService._();

  static final ImageStorageService instance =
      ImageStorageService._();

  static const String _folderName = 'microplastia/samples';

  // Obtiene o crea la carpeta permanente de fotografías.
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

  // Obtiene una extensión válida para el archivo.
  String _getExtension(String filename) {
    final extension = p.extension(filename).toLowerCase();

    const validExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
      '.heic',
      '.heif',
    ];

    if (validExtensions.contains(extension)) {
      return extension;
    }

    return '.jpg';
  }

  // Guarda permanentemente una fotografía.
  // El UUID garantiza que el nombre del archivo sea único.
  Future<String> saveImage({
    required Uint8List bytes,
    required String clientUuid,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('No se puede guardar una imagen vacía.');
    }

    final directory = await _getImageDirectory();

    final extension = _getExtension(filename);

    final filePath = p.join(
      directory.path,
      '$clientUuid$extension',
    );

    final file = File(filePath);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
  }

  // Comprueba si una fotografía todavía existe.
  Future<bool> imageExists(String imagePath) async {
    final file = File(imagePath);
    return file.exists();
  }

  // Recupera los bytes de una fotografía guardada.
  Future<Uint8List> readImage(String imagePath) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception('La fotografía almacenada no existe.');
    }

    return file.readAsBytes();
  }

  // Elimina una fotografía local.
  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}