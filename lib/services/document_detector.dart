import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:dartcv4/dartcv.dart' as cv;

import '../models/scan_models.dart';

/// Parâmetros de detecção derivados da [DetectionSensitivity].
class _DetectionParams {
  const _DetectionParams(this.minAreaFraction, this.cannyThresholds);

  /// Fração mínima da área da imagem que o documento precisa ocupar.
  final double minAreaFraction;

  /// Pares de limiares (baixo, alto) do Canny a experimentar, em ordem.
  final List<(double, double)> cannyThresholds;
}

/// Detecta o contorno de um documento (papel) em uma imagem.
///
/// Pipeline principal (clássico OpenCV, o que já funcionava bem):
/// blur → Canny (vários limiares) → dilate → contornos externos → quad.
///
/// Fallback leve: limiar adaptativo, só se o Canny não achar nada.
///
/// Os cantos são retornados normalizados (0..1) na ordem TL, TR, BR, BL.
class DocumentDetector {
  static const _maxAnalysisSide = 1000;
  static const _maxLiveSide = 720;

  static _DetectionParams _paramsFor(DetectionSensitivity s) => switch (s) {
        DetectionSensitivity.conservative =>
          const _DetectionParams(0.30, [(75.0, 200.0), (50.0, 150.0)]),
        DetectionSensitivity.balanced => const _DetectionParams(
            0.15, [(50.0, 150.0), (30.0, 90.0), (75.0, 200.0)]),
        DetectionSensitivity.sensitive => const _DetectionParams(
            0.08, [(20.0, 60.0), (30.0, 90.0), (50.0, 150.0), (75.0, 200.0)]),
      };

  /// Cantos padrão: imagem inteira com pequena margem.
  static List<Offset> fullImageCorners() => const [
        Offset(0.03, 0.03),
        Offset(0.97, 0.03),
        Offset(0.97, 0.97),
        Offset(0.03, 0.97),
      ];

  /// Detecta os cantos do documento no arquivo de imagem [path].
  /// Retorna a imagem inteira quando nenhum documento é encontrado.
  static Future<List<Offset>> detectFromFile(
    String path, {
    DetectionSensitivity sensitivity = DetectionSensitivity.balanced,
  }) async {
    // imread aplica a orientação EXIF, ao contrário de imdecode.
    final src = await cv.imreadAsync(path, flags: cv.IMREAD_GRAYSCALE);
    try {
      if (src.isEmpty) return fullImageCorners();
      return await detectFromGray(src, sensitivity: sensitivity) ??
          fullImageCorners();
    } finally {
      src.dispose();
    }
  }

  /// Detecta o documento em um [gray] (CV_8UC1). Retorna null se não achar.
  ///
  /// Com [rapido] true (preview), usa resolução menor e pula o fallback.
  static Future<List<Offset>?> detectFromGray(
    cv.Mat gray, {
    DetectionSensitivity sensitivity = DetectionSensitivity.balanced,
    bool rapido = false,
  }) async {
    final w = gray.cols;
    final h = gray.rows;
    final maxSide = rapido ? _maxLiveSide : _maxAnalysisSide;

    final scale = maxSide / math.max(w, h);
    final cv.Mat small;
    if (scale < 1) {
      small = await cv.resizeAsync(
        gray,
        ((w * scale).round(), (h * scale).round()),
        interpolation: cv.INTER_AREA,
      );
    } else {
      small = gray.clone();
    }

    try {
      final blurred = await cv.gaussianBlurAsync(small, (5, 5), 0);
      var quad = await _findBestQuad(blurred, sensitivity);

      // Fallback só na foto completa: papel claro em fundo escuro às vezes
      // falha no Canny e aparece melhor no limiar adaptativo.
      if (quad == null && !rapido) {
        quad = await _findBestQuadAdaptive(blurred, sensitivity);
      }
      blurred.dispose();
      if (quad == null) return null;

      final sw = small.cols.toDouble();
      final sh = small.rows.toDouble();
      return _orderCorners(
        quad.map((p) => Offset(p.x / sw, p.y / sh)).toList(),
      );
    } finally {
      small.dispose();
    }
  }

  /// Canny com vários limiares; escolhe o maior contorno convexo de 4 lados.
  static Future<List<cv.Point2f>?> _findBestQuad(
    cv.Mat blurred,
    DetectionSensitivity sensitivity,
  ) async {
    final params = _paramsFor(sensitivity);
    final imageArea = (blurred.cols * blurred.rows).toDouble();
    List<cv.Point2f>? best;
    var bestArea = imageArea * params.minAreaFraction;

    for (final (t1, t2) in params.cannyThresholds) {
      final edges = await cv.cannyAsync(blurred, t1, t2);
      // Fecha pequenas falhas nas bordas do papel.
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = await cv.dilateAsync(edges, kernel);
      edges.dispose();
      kernel.dispose();

      final candidate = await _largestQuad(closed, bestArea);
      closed.dispose();
      if (candidate != null) {
        best = candidate.points;
        bestArea = candidate.area;
      }

      if (best != null && bestArea > imageArea * 0.4) break;
    }
    return best;
  }

  /// Limiar adaptativo + dilate — fallback quando o Canny não fecha o quad.
  static Future<List<cv.Point2f>?> _findBestQuadAdaptive(
    cv.Mat blurred,
    DetectionSensitivity sensitivity,
  ) async {
    final params = _paramsFor(sensitivity);
    final imageArea = (blurred.cols * blurred.rows).toDouble();
    final minArea = imageArea * params.minAreaFraction;

    final binary = await cv.adaptiveThresholdAsync(
      blurred,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY,
      21,
      5,
    );
    try {
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = await cv.dilateAsync(binary, kernel);
      kernel.dispose();
      final candidate = await _largestQuad(closed, minArea);
      closed.dispose();
      return candidate?.points;
    } finally {
      binary.dispose();
    }
  }

  static Future<({List<cv.Point2f> points, double area})?> _largestQuad(
    cv.Mat binary,
    double minArea,
  ) async {
    final (contours, hierarchy) = await cv.findContoursAsync(
      binary,
      cv.RETR_EXTERNAL,
      cv.CHAIN_APPROX_SIMPLE,
    );
    hierarchy.dispose();

    List<cv.Point2f>? best;
    var bestArea = minArea;

    for (final contour in contours) {
      final area = cv.contourArea(contour);
      if (area < bestArea) continue;

      final peri = cv.arcLength(contour, true);
      // Tenta dois epsilons: o clássico 2% e um um pouco mais frouxo.
      for (final eps in [0.02, 0.04]) {
        final approx = cv.approxPolyDP(contour, eps * peri, true);
        if (approx.length == 4 && cv.isContourConvex(approx)) {
          best = approx
              .map((p) => cv.Point2f(p.x.toDouble(), p.y.toDouble()))
              .toList();
          bestArea = area;
          approx.dispose();
          break;
        }
        approx.dispose();
      }
    }
    contours.dispose();
    if (best == null) return null;
    return (points: best, area: bestArea);
  }

  /// Ordena 4 cantos como TL, TR, BR, BL.
  static List<Offset> _orderCorners(List<Offset> pts) {
    final sorted = List<Offset>.from(pts);
    // Soma menor = topo-esquerda; soma maior = baixo-direita.
    sorted.sort((a, b) => (a.dx + a.dy).compareTo(b.dx + b.dy));
    final tl = sorted.first;
    final br = sorted.last;
    // Diferença (x - y): maior = topo-direita, menor = baixo-esquerda.
    final rest = sorted.sublist(1, 3);
    rest.sort((a, b) => (b.dx - b.dy).compareTo(a.dx - a.dy));
    final tr = rest.first;
    final bl = rest.last;
    return [tl, tr, br, bl];
  }
}
