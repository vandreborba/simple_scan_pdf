import 'dart:ui';

/// Filtros disponíveis por página. Os rótulos ficam em [ScanFilterL10n].
enum ScanFilter {
  original,
  document,
  grayscale,
  blackWhite,
  highContrast,
}

/// Sensibilidade da detecção automática de bordas. Os rótulos ficam em
/// [DetectionSensitivityL10n].
enum DetectionSensitivity {
  conservative,
  balanced,
  sensitive,
}

/// Uma página capturada dentro do documento em andamento.
class ScanPage {
  ScanPage({
    required this.originalPath,
    required this.corners,
    this.filter = ScanFilter.original,
    this.quarterTurns = 0,
  });

  /// Foto original tirada pela câmera.
  final String originalPath;

  /// Cantos normalizados (0..1) na ordem TL, TR, BR, BL.
  List<Offset> corners;

  ScanFilter filter;

  /// Rotações de 90° aplicadas após o recorte (0..3).
  int quarterTurns;

  /// Imagem processada (recortada + filtro), pronta para o PDF.
  String? processedPath;

  /// Incrementado a cada reprocessamento para invalidar cache de imagem.
  int version = 0;

  bool get isProcessed => processedPath != null;
}

/// Linha de texto reconhecida pelo OCR com posição na imagem processada.
class OcrLine {
  OcrLine({required this.text, required this.box});

  final String text;
  final Rect box;
}

/// Resultado do OCR de uma página.
class OcrPageResult {
  OcrPageResult({required this.lines, required this.fullText});

  final List<OcrLine> lines;
  final String fullText;
}
