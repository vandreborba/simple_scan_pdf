import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:dartcv4/dartcv.dart' as cv;

/// Detecta o contorno de um documento (papel) em uma imagem.
///
/// Os cantos são retornados normalizados (0..1) na ordem TL, TR, BR, BL.
class DocumentDetector {
  static const _maxAnalysisSide = 1000;

  /// Cantos padrão: imagem inteira com pequena margem.
  static List<Offset> fullImageCorners() => const [
        Offset(0.03, 0.03),
        Offset(0.97, 0.03),
        Offset(0.97, 0.97),
        Offset(0.03, 0.97),
      ];

  /// Detecta os cantos do documento no arquivo de imagem [path].
  /// Retorna a imagem inteira quando nenhum documento é encontrado.
  static Future<List<Offset>> detectFromFile(String path) async {
    // imread aplica a orientação EXIF, ao contrário de imdecode.
    final src = await cv.imreadAsync(path, flags: cv.IMREAD_GRAYSCALE);
    try {
      if (src.isEmpty) return fullImageCorners();
      return await detectFromGray(src) ?? fullImageCorners();
    } finally {
      src.dispose();
    }
  }

  /// Detecta o documento em um [gray] (CV_8UC1). Retorna null se não achar.
  static Future<List<Offset>?> detectFromGray(cv.Mat gray) async {
    final w = gray.cols;
    final h = gray.rows;

    // Reduz para acelerar a análise.
    final scale = _maxAnalysisSide / math.max(w, h);
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
      final quad = await _findBestQuad(blurred, small.cols, small.rows);
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

  /// Tenta encontrar o melhor quadrilátero usando Canny com mais de um
  /// limiar, escolhendo o maior contorno convexo de 4 lados.
  static Future<List<cv.Point2f>?> _findBestQuad(
    cv.Mat blurred,
    int width,
    int height,
  ) async {
    final imageArea = (width * height).toDouble();
    List<cv.Point2f>? best;
    var bestArea = imageArea * 0.15; // área mínima: 15% da imagem

    for (final (t1, t2) in const [(50.0, 150.0), (30.0, 90.0), (75.0, 200.0)]) {
      final edges = await cv.cannyAsync(blurred, t1, t2);
      // Fecha pequenas falhas nas bordas do papel.
      final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
      final closed = await cv.dilateAsync(edges, kernel);
      edges.dispose();
      kernel.dispose();

      final (contours, hierarchy) = await cv.findContoursAsync(
        closed,
        cv.RETR_EXTERNAL,
        cv.CHAIN_APPROX_SIMPLE,
      );
      closed.dispose();
      hierarchy.dispose();

      for (final contour in contours) {
        final area = cv.contourArea(contour);
        if (area < bestArea) continue;

        final peri = cv.arcLength(contour, true);
        final approx = cv.approxPolyDP(contour, 0.02 * peri, true);
        if (approx.length == 4 && cv.isContourConvex(approx)) {
          best = approx
              .map((p) => cv.Point2f(p.x.toDouble(), p.y.toDouble()))
              .toList();
          bestArea = area;
        }
        approx.dispose();
      }
      contours.dispose();

      // Um quadrilátero grande já é bom o suficiente.
      if (best != null && bestArea > imageArea * 0.4) break;
    }
    return best;
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
