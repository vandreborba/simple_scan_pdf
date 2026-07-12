import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:dartcv4/dartcv.dart' as cv;

import '../models/scan_models.dart';
import 'document_detector.dart';

/// Roda a detecção de documento sobre frames da câmera (plano Y do YUV),
/// descartando frames enquanto uma análise está em andamento.
class LiveDetector {
  bool _busy = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  /// Analisa um frame da câmera. O retorno tem três significados:
  /// - lista com 4 cantos: documento encontrado (já no espaço do preview);
  /// - lista vazia: analisou e não achou documento (limpa o overlay);
  /// - null: frame descartado (throttle/ocupado) — mantenha o estado atual.
  Future<List<Offset>?> analyze(
    CameraImage image,
    int sensorOrientation, {
    DetectionSensitivity sensitivity = DetectionSensitivity.balanced,
  }) async {
    if (_busy) return null;
    final now = DateTime.now();
    if (now.difference(_lastRun).inMilliseconds < 250) return null;
    _busy = true;
    _lastRun = now;

    try {
      final gray = _grayFromYuv(image);
      if (gray == null) return null;
      try {
        final corners = await DocumentDetector.detectFromGray(
          gray,
          sensitivity: sensitivity,
          rapido: true,
        );
        // Analisou mas não achou: lista vazia (diferente de frame descartado).
        if (corners == null) return const <Offset>[];
        return corners
            .map((c) => _rotateToPreview(c, sensorOrientation))
            .toList();
      } finally {
        gray.dispose();
      }
    } catch (_) {
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Extrai o plano de luminância (Y) como Mat cinza, respeitando o stride.
  cv.Mat? _grayFromYuv(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final width = image.width;
    final height = image.height;
    final stride = plane.bytesPerRow;

    Uint8List packed;
    if (stride == width) {
      packed = plane.bytes;
    } else {
      packed = Uint8List(width * height);
      for (var row = 0; row < height; row++) {
        final start = row * stride;
        packed.setRange(row * width, (row + 1) * width,
            plane.bytes.sublist(start, start + width));
      }
    }
    return cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, packed);
  }

  /// Converte um ponto normalizado do frame do sensor para o espaço do
  /// preview em pé (portrait), conforme a orientação do sensor.
  Offset _rotateToPreview(Offset p, int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return Offset(1 - p.dy, p.dx);
      case 180:
        return Offset(1 - p.dx, 1 - p.dy);
      case 270:
        return Offset(p.dy, 1 - p.dx);
      default:
        return p;
    }
  }
}
