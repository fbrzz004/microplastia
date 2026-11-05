import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_update_service.dart';

class TfliteDetection {
  final int classId;
  final String className;
  final double confidence;

  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const TfliteDetection({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  Map<String, dynamic> toJson() {
    return {
      'class_id': classId,
      'class_name': className,
      'confidence': confidence,
      'box': [
        x1,
        y1,
        x2,
        y2,
      ],
    };
  }

  @override
  String toString() {
    return 'TfliteDetection('
        'class=$className, '
        'confidence=${confidence.toStringAsFixed(4)}, '
        'box=['
        '${x1.toStringAsFixed(1)}, '
        '${y1.toStringAsFixed(1)}, '
        '${x2.toStringAsFixed(1)}, '
        '${y2.toStringAsFixed(1)}'
        '])';
  }
}

class TfliteAnalysisResult {
  final List<TfliteDetection> detections;
  final int inferenceTimeMs;

  final String modelSource;

  final String modelVersion;
  final String modelName;

  const TfliteAnalysisResult({
    required this.detections,
    required this.inferenceTimeMs,
    required this.modelVersion,
    required this.modelName,
    required this.modelSource,
  });

  int get totalParticles => detections.length;

  double get averageConfidence {
    if (detections.isEmpty) {
      return 0.0;
    }

    final total = detections.fold<double>(
      0.0,
      (sum, detection) {
        return sum + detection.confidence;
      },
    );

    return total / detections.length;
  }

  Map<String, int> get breakdown {
    final result = <String, int>{};

    for (final detection in detections) {
      result[detection.className] = (result[detection.className] ?? 0) + 1;
    }

    return result;
  }
}

class TfliteInferenceService {
  static const String _assetModelPath = 'assets/models/best.tflite';

  static const String _fallbackVersion = '1.0.0';

  static const String _fallbackModelName = 'YOLOv8n';

  static const int _fallbackInputSize = 320;

  static const double _fallbackConfidenceThreshold = 0.25;

  static const double _fallbackIouThreshold = 0.7;

  String _activeModelSource = 'fallback';

  static const Map<int, String> _fallbackClassNames = {
    0: 'partícula orgánica',
    1: 'fibra',
    2: 'fragmento',
    3: 'gránulo',
  };

  final ModelUpdateService _modelUpdateService = ModelUpdateService();

  Interpreter? _interpreter;

  String _activeModelVersion = _fallbackVersion;

  String _activeModelName = _fallbackModelName;

  int _inputSize = _fallbackInputSize;

  double _confidenceThreshold = _fallbackConfidenceThreshold;

  double _iouThreshold = _fallbackIouThreshold;

  Map<int, String> _classNames = Map<int, String>.from(
    _fallbackClassNames,
  );

  bool get isLoaded => _interpreter != null;

  String get activeModelVersion => _activeModelVersion;

  String get activeModelName => _activeModelName;

  Future<void> loadModel() async {
    if (_interpreter != null) {
      return;
    }

    // ==========================================
    // INTENTAR ACTUALIZACIÓN
    // ==========================================

    try {
      final updateResult = await _modelUpdateService.checkForUpdate();

      final metadata = updateResult.metadata;

      _activeModelVersion = metadata.version;

      _activeModelName = metadata.nombre;

      _inputSize = metadata.inputSize;

      _confidenceThreshold = metadata.confidenceThreshold;

      _iouThreshold = metadata.iouThreshold;

      if (metadata.clases.isNotEmpty) {
        _classNames = Map<int, String>.from(
          metadata.clases,
        );
      }

      final localPath = updateResult.localModelPath;

      if (localPath != null && localPath.trim().isNotEmpty) {
        final file = File(
          localPath,
        );

        if (await file.exists()) {
          try {
            _interpreter = Interpreter.fromFile(
              file,
            );

            _activeModelSource = 'downloaded';

            debugPrint(
              '✅ Modelo descargado cargado: '
              '${metadata.nombre} '
              'v${metadata.version}',
            );

            _printTensorInfo();

            return;
          } catch (e) {
            debugPrint(
              '⚠️ No se pudo cargar '
              'el modelo descargado: $e',
            );

            _interpreter?.close();
            _interpreter = null;
          }
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️ No se pudo verificar '
        'actualización del modelo: $e',
      );
    }

    // ==========================================
    // FALLBACK: MODELO INCLUIDO EN APK
    // ==========================================

    await _loadAssetFallback();
  }

  Future<void> _loadAssetFallback() async {
    _activeModelSource = 'fallback';

    _activeModelVersion = _fallbackVersion;

    _activeModelName = _fallbackModelName;

    _inputSize = _fallbackInputSize;

    _confidenceThreshold = _fallbackConfidenceThreshold;

    _iouThreshold = _fallbackIouThreshold;

    _classNames = Map<int, String>.from(
      _fallbackClassNames,
    );

    _interpreter = await Interpreter.fromAsset(
      _assetModelPath,
    );

    debugPrint(
      '✅ Modelo base cargado desde APK: '
      '$_activeModelName '
      'v$_activeModelVersion',
    );

    _printTensorInfo();
  }

  void _printTensorInfo() {
    if (_interpreter == null) {
      return;
    }

    debugPrint(
      'Input tensors: '
      '${_interpreter!.getInputTensors()}',
    );

    debugPrint(
      'Output tensors: '
      '${_interpreter!.getOutputTensors()}',
    );
  }

  Future<TfliteAnalysisResult> analyzeImage(
    Uint8List imageBytes,
  ) async {
    if (_interpreter == null) {
      await loadModel();
    }

    final decodedImage = img.decodeImage(
      imageBytes,
    );

    if (decodedImage == null) {
      throw Exception(
        'No se pudo decodificar la imagen.',
      );
    }

    // ==========================================
    // VALIDAR ESTRUCTURA DEL MODELO
    // ==========================================

    final inputTensors = _interpreter!.getInputTensors();

    final outputTensors = _interpreter!.getOutputTensors();

    if (inputTensors.isEmpty || outputTensors.isEmpty) {
      throw Exception(
        'El modelo no tiene tensores válidos.',
      );
    }

    final outputShape = outputTensors.first.shape;

    if (outputShape.length != 3) {
      throw Exception(
        'El modelo TFLite tiene '
        'una salida incompatible.',
      );
    }

    final outputRows = outputShape[1];

    final predictionCount = outputShape[2];

    final classCount = outputRows - 4;

    if (classCount <= 0 || predictionCount <= 0) {
      throw Exception(
        'La estructura de salida '
        'del modelo no es válida.',
      );
    }

    // ==========================================
    // PREPROCESAMIENTO
    // ==========================================

    final originalWidth = decodedImage.width;

    final originalHeight = decodedImage.height;

    final scale = math.min(
      _inputSize / originalWidth,
      _inputSize / originalHeight,
    );

    final resizedWidth = math.max(
      1,
      (originalWidth * scale).round(),
    );

    final resizedHeight = math.max(
      1,
      (originalHeight * scale).round(),
    );

    final resized = img.copyResize(
      decodedImage,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.linear,
    );

    final paddingX = (_inputSize - resizedWidth) ~/ 2;

    final paddingY = (_inputSize - resizedHeight) ~/ 2;

    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (_) => List.generate(
          _inputSize,
          (_) => List<double>.filled(
            _inputSize,
            114.0 / 255.0,
          ),
        ),
      ),
    );

    for (int y = 0; y < resizedHeight; y++) {
      for (int x = 0; x < resizedWidth; x++) {
        final pixel = resized.getPixel(
          x,
          y,
        );

        final targetX = x + paddingX;

        final targetY = y + paddingY;

        input[0][0][targetY][targetX] = pixel.r.toDouble() / 255.0;

        input[0][1][targetY][targetX] = pixel.g.toDouble() / 255.0;

        input[0][2][targetY][targetX] = pixel.b.toDouble() / 255.0;
      }
    }

    // ==========================================
    // OUTPUT DINÁMICO
    // ==========================================

    final output = List.generate(
      1,
      (_) => List.generate(
        outputRows,
        (_) => List<double>.filled(
          predictionCount,
          0.0,
        ),
      ),
    );

    final stopwatch = Stopwatch()..start();

    _interpreter!.run(
      input,
      output,
    );

    stopwatch.stop();

    // ==========================================
    // POSTPROCESAMIENTO
    // ==========================================

    final rawDetections = <TfliteDetection>[];

    for (int predictionIndex = 0;
        predictionIndex < predictionCount;
        predictionIndex++) {
      int bestClassId = 0;

      double bestConfidence = output[0][4][predictionIndex];

      for (int classId = 1; classId < classCount; classId++) {
        final confidence = output[0][4 + classId][predictionIndex];

        if (confidence > bestConfidence) {
          bestConfidence = confidence;

          bestClassId = classId;
        }
      }

      if (bestConfidence < _confidenceThreshold) {
        continue;
      }

      final centerX = output[0][0][predictionIndex] * _inputSize;

      final centerY = output[0][1][predictionIndex] * _inputSize;

      final width = output[0][2][predictionIndex] * _inputSize;

      final height = output[0][3][predictionIndex] * _inputSize;

      double x1 = centerX - (width / 2.0);

      double y1 = centerY - (height / 2.0);

      double x2 = centerX + (width / 2.0);

      double y2 = centerY + (height / 2.0);

      x1 = (x1 - paddingX) / scale;

      y1 = (y1 - paddingY) / scale;

      x2 = (x2 - paddingX) / scale;

      y2 = (y2 - paddingY) / scale;

      x1 = x1.clamp(
        0.0,
        originalWidth.toDouble(),
      );

      y1 = y1.clamp(
        0.0,
        originalHeight.toDouble(),
      );

      x2 = x2.clamp(
        0.0,
        originalWidth.toDouble(),
      );

      y2 = y2.clamp(
        0.0,
        originalHeight.toDouble(),
      );

      if (x2 <= x1 || y2 <= y1) {
        continue;
      }

      rawDetections.add(
        TfliteDetection(
          classId: bestClassId,
          className: _classNames[bestClassId] ?? 'desconocida',
          confidence: bestConfidence,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
        ),
      );
    }

    final detections = _applyNms(
      rawDetections,
    );

    debugPrint(
      '✅ Inferencia TFLite: '
      '${stopwatch.elapsedMilliseconds} ms',
    );

    debugPrint(
      '✅ Modelo utilizado: '
      '$_activeModelName '
      'v$_activeModelVersion',
    );

    debugPrint(
      '✅ Detecciones: '
      '${detections.length}',
    );

    return TfliteAnalysisResult(
      detections: detections,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
      modelVersion: _activeModelVersion,
      modelName: _activeModelName,
      modelSource: _activeModelSource,
    );
  }

  List<TfliteDetection> _applyNms(
    List<TfliteDetection> detections,
  ) {
    final sorted = List<TfliteDetection>.from(
      detections,
    );

    sorted.sort(
      (a, b) => b.confidence.compareTo(
        a.confidence,
      ),
    );

    final selected = <TfliteDetection>[];

    while (sorted.isNotEmpty) {
      final current = sorted.removeAt(
        0,
      );

      selected.add(
        current,
      );

      sorted.removeWhere(
        (candidate) {
          if (candidate.classId != current.classId) {
            return false;
          }

          final iou = _calculateIoU(
            current,
            candidate,
          );

          return iou > _iouThreshold;
        },
      );
    }

    return selected;
  }

  double _calculateIoU(
    TfliteDetection a,
    TfliteDetection b,
  ) {
    final intersectionX1 = math.max(
      a.x1,
      b.x1,
    );

    final intersectionY1 = math.max(
      a.y1,
      b.y1,
    );

    final intersectionX2 = math.min(
      a.x2,
      b.x2,
    );

    final intersectionY2 = math.min(
      a.y2,
      b.y2,
    );

    final intersectionWidth = math.max(
      0.0,
      intersectionX2 - intersectionX1,
    );

    final intersectionHeight = math.max(
      0.0,
      intersectionY2 - intersectionY1,
    );

    final intersectionArea = intersectionWidth * intersectionHeight;

    final areaA = math.max(
          0.0,
          a.x2 - a.x1,
        ) *
        math.max(
          0.0,
          a.y2 - a.y1,
        );

    final areaB = math.max(
          0.0,
          b.x2 - b.x1,
        ) *
        math.max(
          0.0,
          b.y2 - b.y1,
        );

    final unionArea = areaA + areaB - intersectionArea;

    if (unionArea <= 0) {
      return 0.0;
    }

    return intersectionArea / unionArea;
  }

  void close() {
    _interpreter?.close();

    _interpreter = null;
  }
}
