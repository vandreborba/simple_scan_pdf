import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:dartcv4/dartcv.dart' as cv;
import 'package:path_provider/path_provider.dart';

import '../models/scan_models.dart';

/// Recorta (correção de perspectiva), gira e aplica filtro em uma página,
/// gravando o resultado como JPEG.
class ImageProcessor {
  static const _jpegQuality = 85;
  static const _maxOutputSide = 2400;

  /// Processa [page] e devolve o caminho do JPEG resultante.
  static Future<String> process(ScanPage page) async {
    // imread aplica a orientação EXIF, ao contrário de imdecode.
    var mat = await cv.imreadAsync(page.originalPath, flags: cv.IMREAD_COLOR);
    try {
      mat = _limitSize(mat);
      final warped = await _warp(mat, page.corners);
      mat.dispose();

      var result = warped;
      for (var i = 0; i < page.quarterTurns % 4; i++) {
        final rotated = result.rotate(cv.ROTATE_90_CLOCKWISE);
        result.dispose();
        result = rotated;
      }

      final filtered = await _applyFilter(result, page.filter);
      if (!identical(filtered, result)) result.dispose();

      final dir = await getApplicationDocumentsDirectory();
      final outPath =
          '${dir.path}/page_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final params = cv.VecI32.fromList([cv.IMWRITE_JPEG_QUALITY, _jpegQuality]);
      cv.imwrite(outPath, filtered, params: params);
      filtered.dispose();
      return outPath;
    } catch (_) {
      mat.dispose();
      rethrow;
    }
  }

  static cv.Mat _limitSize(cv.Mat src) {
    final maxSide = math.max(src.cols, src.rows);
    if (maxSide <= _maxOutputSide) return src;
    final scale = _maxOutputSide / maxSide;
    final resized = cv.resize(
      src,
      ((src.cols * scale).round(), (src.rows * scale).round()),
      interpolation: cv.INTER_AREA,
    );
    src.dispose();
    return resized;
  }

  /// Correção de perspectiva a partir dos cantos normalizados (TL,TR,BR,BL).
  static Future<cv.Mat> _warp(cv.Mat src, List<Offset> corners) async {
    final w = src.cols.toDouble();
    final h = src.rows.toDouble();
    final pts = corners
        .map((c) => cv.Point2f(
              (c.dx * w).clamp(0, w - 1).toDouble(),
              (c.dy * h).clamp(0, h - 1).toDouble(),
            ))
        .toList();

    double dist(cv.Point2f a, cv.Point2f b) =>
        math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

    final outW = math.max(dist(pts[0], pts[1]), dist(pts[3], pts[2])).round();
    final outH = math.max(dist(pts[0], pts[3]), dist(pts[1], pts[2])).round();
    if (outW < 20 || outH < 20) return src.clone();

    final srcVec = cv.VecPoint2f.fromList(pts);
    final dstVec = cv.VecPoint2f.fromList([
      cv.Point2f(0, 0),
      cv.Point2f(outW - 1, 0),
      cv.Point2f(outW - 1, outH - 1),
      cv.Point2f(0, outH - 1),
    ]);
    final m = await cv.getPerspectiveTransform2fAsync(srcVec, dstVec);
    final warped = await cv.warpPerspectiveAsync(src, m, (outW, outH));
    m.dispose();
    srcVec.dispose();
    dstVec.dispose();
    return warped;
  }

  static Future<cv.Mat> _applyFilter(cv.Mat src, ScanFilter filter) async {
    switch (filter) {
      case ScanFilter.original:
        return src;

      case ScanFilter.grayscale:
        final gray = await cv.cvtColorAsync(src, cv.COLOR_BGR2GRAY);
        final back = await cv.cvtColorAsync(gray, cv.COLOR_GRAY2BGR);
        gray.dispose();
        return back;

      case ScanFilter.blackWhite:
        final gray = await cv.cvtColorAsync(src, cv.COLOR_BGR2GRAY);
        final bw = await cv.adaptiveThresholdAsync(
          gray,
          255,
          cv.ADAPTIVE_THRESH_GAUSSIAN_C,
          cv.THRESH_BINARY,
          21,
          10,
        );
        gray.dispose();
        final back = await cv.cvtColorAsync(bw, cv.COLOR_GRAY2BGR);
        bw.dispose();
        return back;

      case ScanFilter.document:
        // "Realce de documento": remove sombras dividindo pela iluminação
        // de fundo estimada (blur pesado), mantendo as cores suaves.
        final gray = await cv.cvtColorAsync(src, cv.COLOR_BGR2GRAY);
        final background = await cv.gaussianBlurAsync(gray, (55, 55), 0);
        final normalized = cv.divide(gray, background, scale: 255);
        gray.dispose();
        background.dispose();
        final enhanced = cv.convertScaleAbs(normalized, alpha: 1.15, beta: -20);
        normalized.dispose();
        final back = await cv.cvtColorAsync(enhanced, cv.COLOR_GRAY2BGR);
        enhanced.dispose();
        return back;

      case ScanFilter.highContrast:
        return cv.convertScaleAbs(src, alpha: 1.4, beta: -40);
    }
  }
}
