import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'tflite_inference_service.dart';

class AnnotationService {
  static Uint8List generateAnnotatedImage({
    required Uint8List originalBytes,
    required TfliteAnalysisResult result,
  }) {
    final image = img.decodeImage(originalBytes);

    if (image == null) {
      throw Exception(
        'No se pudo decodificar la imagen para dibujar las detecciones.',
      );
    }

    for (final detection in result.detections) {
      final data = detection.toJson();

      final box = data['box'];

      if (box is! List || box.length != 4) {
        continue;
      }

      final x1 = (box[0] as num)
          .round()
          .clamp(0, image.width - 1);

      final y1 = (box[1] as num)
          .round()
          .clamp(0, image.height - 1);

      final x2 = (box[2] as num)
          .round()
          .clamp(0, image.width - 1);

      final y2 = (box[3] as num)
          .round()
          .clamp(0, image.height - 1);

      final classId =
          (data['class_id'] as num?)?.toInt() ?? -1;

      final color = _colorForClass(classId);

      img.drawRect(
        image,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        color: color,
        thickness: 4,
      );
    }

    final jpg = img.encodeJpg(
      image,
      quality: 90,
    );

    return Uint8List.fromList(jpg);
  }

  static img.Color _colorForClass(int classId) {
    switch (classId) {
      case 0:
      // Partícula orgánica
        return img.ColorRgb8(
          156,
          39,
          176,
        );

      case 1:
      // Fibra
        return img.ColorRgb8(
          33,
          150,
          243,
        );

      case 2:
      // Fragmento
        return img.ColorRgb8(
          0,
          200,
          120,
        );

      case 3:
      // Gránulo
        return img.ColorRgb8(
          255,
          152,
          0,
        );

      default:
        return img.ColorRgb8(
          255,
          255,
          255,
        );
    }
  }
}